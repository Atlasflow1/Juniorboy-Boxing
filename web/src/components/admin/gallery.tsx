'use client';

import { ChangeEvent, FormEvent, useState } from 'react';
import {
  collection,
  doc,
  setDoc,
  deleteDoc,
  updateDoc,
  serverTimestamp,
  writeBatch,
  orderBy,
} from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage';
import { db, storage } from '@/lib/firebase';
import { useRows } from '@/lib/hooks';
import { GalleryPhoto } from '@/lib/types';
import { errorMessage } from '@/lib/utils';
import { Button, Notice, PageHeading, Modal, Loading, Icon } from '../ui';
import { useAuth } from '../providers';

async function prepareImage(file: File): Promise<{ blob: Blob; ext: string }> {
  return new Promise((resolve) => {
    if (typeof window === 'undefined' || typeof Image === 'undefined') {
      const ext = file.name.split('.').pop()?.toLowerCase() || 'jpg';
      resolve({ blob: file, ext });
      return;
    }

    const img = new Image();
    const objectUrl = URL.createObjectURL(file);

    img.onload = () => {
      URL.revokeObjectURL(objectUrl);
      const maxDim = 1600;
      let { width, height } = img;
      if (width > maxDim || height > maxDim) {
        if (width > height) {
          height = Math.round((height * maxDim) / width);
          width = maxDim;
        } else {
          width = Math.round((width * maxDim) / height);
          height = maxDim;
        }
      }

      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext('2d');
      if (!ctx) {
        const ext = file.type === 'image/png' ? 'png' : file.type === 'image/webp' ? 'webp' : 'jpg';
        resolve({ blob: file, ext });
        return;
      }
      ctx.drawImage(img, 0, 0, width, height);

      const mimeType =
        file.type === 'image/png'
          ? 'image/png'
          : file.type === 'image/webp'
          ? 'image/webp'
          : 'image/jpeg';
      const ext = mimeType === 'image/png' ? 'png' : mimeType === 'image/webp' ? 'webp' : 'jpg';

      canvas.toBlob(
        (b) => {
          if (b) {
            resolve({ blob: b, ext });
          } else {
            resolve({ blob: file, ext });
          }
        },
        mimeType,
        0.88
      );
    };

    img.onerror = () => {
      URL.revokeObjectURL(objectUrl);
      const ext = file.type === 'image/png' ? 'png' : file.type === 'image/webp' ? 'webp' : 'jpg';
      resolve({ blob: file, ext });
    };

    img.src = objectUrl;
  });
}

export function AdminGallery() {
  const { user } = useAuth();
  const data = useRows('galleryPhotos', [orderBy('sortOrder', 'asc')]);
  const [selectedPhoto, setSelectedPhoto] = useState<GalleryPhoto | null>(null);
  const [busy, setBusy] = useState(false);
  const [uploadStatus, setUploadStatus] = useState('');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  const photos = [...(data.rows as GalleryPhoto[])].sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0));

  async function handleUpload(e: ChangeEvent<HTMLInputElement>) {
    const files = e.target.files;
    if (!files || files.length === 0) return;
    setError('');
    setMessage('');
    setBusy(true);

    const fileList = Array.from(files);
    let uploadedCount = 0;
    const currentMaxOrder = photos.reduce((max, p) => Math.max(max, p.sortOrder ?? 0), -1);

    try {
      for (let i = 0; i < fileList.length; i++) {
        const file = fileList[i];
        if (file.size > 5 * 1024 * 1024) {
          setError(`"${file.name}" is larger than 5 MB. Please select images under 5 MB.`);
          continue;
        }
        if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
          setError(`"${file.name}" is not a JPG, PNG, or WebP image.`);
          continue;
        }

        setUploadStatus(`Uploading ${i + 1} of ${fileList.length}...`);
        const { blob, ext } = await prepareImage(file);
        const id = crypto.randomUUID();
        const storagePath = `gym/gallery/${id}.${ext}`;
        const fileRef = ref(storage, storagePath);

        await uploadBytes(fileRef, blob, { contentType: blob.type || file.type });
        const imageUrl = await getDownloadURL(fileRef);

        const newOrder = currentMaxOrder + 1 + uploadedCount;
        await setDoc(doc(db, 'galleryPhotos', id), {
          imageUrl,
          storagePath,
          caption: null,
          isVisible: true,
          sortOrder: newOrder,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
          createdBy: user?.uid || '',
        });
        uploadedCount++;
      }
      if (uploadedCount > 0) {
        setMessage(`Successfully uploaded ${uploadedCount} photo${uploadedCount > 1 ? 's' : ''}.`);
      }
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
      setUploadStatus('');
      e.target.value = '';
    }
  }

  async function toggleVisibility(photo: GalleryPhoto) {
    setError('');
    try {
      await updateDoc(doc(db, 'galleryPhotos', photo.id), {
        isVisible: !photo.isVisible,
        updatedAt: serverTimestamp(),
      });
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  async function move(fromId: string, toId: string) {
    setError('');
    const next = [...photos];
    const fromIndex = next.findIndex((p) => p.id === fromId);
    const toIndex = next.findIndex((p) => p.id === toId);
    if (fromIndex < 0 || toIndex < 0) return;

    const [item] = next.splice(fromIndex, 1);
    next.splice(toIndex, 0, item);

    const batch = writeBatch(db);
    next.forEach((p, index) => {
      batch.update(doc(db, 'galleryPhotos', p.id), {
        sortOrder: index,
        updatedAt: serverTimestamp(),
      });
    });

    try {
      await batch.commit();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  async function removePhoto(photo: GalleryPhoto) {
    if (!window.confirm('Delete this photo? This will permanently remove it from the gallery.')) {
      return;
    }
    setError('');
    setBusy(true);
    try {
      if (photo.storagePath) {
        try {
          await deleteObject(ref(storage, photo.storagePath));
        } catch (storageErr) {
          console.warn('Storage deletion error:', storageErr);
        }
      }
      await deleteDoc(doc(db, 'galleryPhotos', photo.id));
      if (selectedPhoto?.id === photo.id) {
        setSelectedPhoto(null);
      }
      setMessage('Photo deleted.');
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <PageHeading title="Kids photos" eyebrow="Admin">
        Photos shown on the home page in &apos;Our fighters, in their corner&apos;.
      </PageHeading>

      <div style={{ marginBottom: 20 }}>
        <Notice>
          Only post photos you have parent permission to share. Do not include children&apos;s names.
        </Notice>
      </div>

      <div className="admin-toolbar" style={{ flexWrap: 'wrap', gap: 12 }}>
        <label className="button" style={{ cursor: busy ? 'not-allowed' : 'pointer' }}>
          <Icon name="add_photo_alternate" size={18} />
          {busy && uploadStatus ? uploadStatus : 'Upload Photos'}
          <input
            type="file"
            multiple
            accept="image/jpeg,image/png,image/webp"
            disabled={busy}
            style={{ display: 'none' }}
            onChange={handleUpload}
          />
        </label>
        <span className="muted" style={{ fontSize: 13, alignSelf: 'center' }}>
          JPG, PNG, or WebP · Up to 5 MB per photo · Client downscaled to 1600px
        </span>
      </div>

      {(error || data.error) && <Notice error>{error || data.error}</Notice>}
      {message && <Notice>{message}</Notice>}

      {data.loading ? (
        <Loading />
      ) : photos.length === 0 ? (
        <div className="empty card stack" style={{ textAlign: 'center', padding: 40, alignItems: 'center' }}>
          <p style={{ margin: 0, fontSize: 16 }}>No photos in the gallery yet.</p>
          <p className="muted" style={{ margin: 0, fontSize: 14 }}>
            Photos shown on the home page in &apos;Our fighters, in their corner&apos;.
          </p>
          <label className="button" style={{ cursor: busy ? 'not-allowed' : 'pointer', marginTop: 12 }}>
            <Icon name="add_photo_alternate" size={18} />
            {busy && uploadStatus ? uploadStatus : 'Add photos'}
            <input
              type="file"
              multiple
              accept="image/jpeg,image/png,image/webp"
              disabled={busy}
              style={{ display: 'none' }}
              onChange={handleUpload}
            />
          </label>
        </div>
      ) : (
        <div className="stack" style={{ gap: 12 }}>
          {photos.map((photo, index) => (
            <article
              key={photo.id}
              className="card row spread"
              style={{
                alignItems: 'center',
                padding: '12px 16px',
                opacity: photo.isVisible ? 1 : 0.6,
                background: photo.isVisible ? 'var(--surface)' : 'rgba(128,128,128,0.06)',
              }}
            >
              <div className="row" style={{ alignItems: 'center', gap: 14, minWidth: 0 }}>
                <img
                  src={photo.imageUrl}
                  alt={photo.caption || 'Gallery photo'}
                  style={{
                    width: 60,
                    height: 75,
                    objectFit: 'cover',
                    borderRadius: 4,
                    flexShrink: 0,
                  }}
                />
                <div style={{ minWidth: 0 }}>
                  <p
                    style={{
                      margin: 0,
                      fontWeight: 600,
                      fontSize: 14,
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                    }}
                  >
                    {photo.caption || <span className="muted">No caption</span>}
                  </p>
                  <p className="muted" style={{ margin: '4px 0 0', fontSize: 12 }}>
                    {photo.isVisible ? 'Visible on site' : 'Hidden'} · Order: {photo.sortOrder ?? index}
                  </p>
                </div>
              </div>

              <div className="row" style={{ alignItems: 'center', gap: 8, flexShrink: 0 }}>
                <Button
                  type="button"
                  className="secondary small"
                  onClick={() => toggleVisibility(photo)}
                  title={photo.isVisible ? 'Hide from public site' : 'Show on public site'}
                >
                  {photo.isVisible ? 'Hide' : 'Show'}
                </Button>

                <Button
                  type="button"
                  className="text small"
                  aria-label="Move up"
                  disabled={index === 0}
                  onClick={() => move(photo.id, photos[index - 1].id)}
                >
                  ↑
                </Button>

                <Button
                  type="button"
                  className="text small"
                  aria-label="Move down"
                  disabled={index === photos.length - 1}
                  onClick={() => move(photo.id, photos[index + 1].id)}
                >
                  ↓
                </Button>

                <Button
                  type="button"
                  className="secondary small"
                  onClick={() => setSelectedPhoto(photo)}
                >
                  Edit
                </Button>

                <Button
                  type="button"
                  className="text small"
                  style={{ color: 'var(--red, #D70015)' }}
                  onClick={() => removePhoto(photo)}
                  title="Delete photo"
                >
                  <Icon name="delete" size={16} />
                </Button>
              </div>
            </article>
          ))}
        </div>
      )}

      {selectedPhoto && (
        <PhotoEditorModal
          photo={selectedPhoto}
          onClose={() => setSelectedPhoto(null)}
          onDelete={() => removePhoto(selectedPhoto)}
        />
      )}
    </>
  );
}

function PhotoEditorModal({
  photo,
  onClose,
  onDelete,
}: {
  photo: GalleryPhoto;
  onClose: () => void;
  onDelete: () => void;
}) {
  const [caption, setCaption] = useState(photo.caption || '');
  const [isVisible, setIsVisible] = useState(photo.isVisible ?? true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function save(e: FormEvent) {
    e.preventDefault();
    if (caption.length > 80) {
      setError('Caption must be 80 characters or fewer.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      await updateDoc(doc(db, 'galleryPhotos', photo.id), {
        caption: caption.trim() ? caption.trim() : null,
        isVisible,
        updatedAt: serverTimestamp(),
      });
      onClose();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal title="Edit Photo" onClose={onClose}>
      <form className="stack" onSubmit={save}>
        <div style={{ textAlign: 'center', margin: '8px 0' }}>
          <img
            src={photo.imageUrl}
            alt={caption || 'Preview'}
            style={{
              maxHeight: 260,
              maxWidth: '100%',
              objectFit: 'contain',
              borderRadius: 6,
            }}
          />
        </div>

        <label className="field">
          Caption (optional, max 80 characters)
          <input
            value={caption}
            maxLength={80}
            placeholder="e.g. Focus on fundamentals"
            onChange={(e) => setCaption(e.target.value)}
          />
          <span className="muted" style={{ fontSize: 11, textAlign: 'right' }}>
            {caption.length} / 80
          </span>
        </label>

        <p className="muted" style={{ fontSize: 12, margin: 0 }}>
          Do not include children&apos;s names in the caption.
        </p>

        <label className="check-field">
          <input
            type="checkbox"
            checked={isVisible}
            onChange={(e) => setIsVisible(e.target.checked)}
          />
          Visible in public gallery
        </label>

        {error && <Notice error>{error}</Notice>}

        <div className="row spread" style={{ marginTop: 12 }}>
          <Button busy={busy}>Save Changes</Button>
          <Button
            type="button"
            className="secondary"
            onClick={onDelete}
            style={{ color: 'var(--red, #D70015)' }}
          >
            Delete Photo
          </Button>
        </div>
      </form>
    </Modal>
  );
}
