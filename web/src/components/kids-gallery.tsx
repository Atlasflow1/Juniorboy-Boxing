'use client';

import { useEffect, useRef, useState } from 'react';
import { where } from 'firebase/firestore';
import { useRows } from '@/lib/hooks';
import { GalleryPhoto } from '@/lib/types';
import styles from './kids-gallery.module.css';

function formatMonthYear(val: any): string {
  if (!val) return '';
  let date: Date | null = null;
  if (typeof val?.toDate === 'function') {
    date = val.toDate();
  } else if (val?.seconds) {
    date = new Date(val.seconds * 1000);
  } else if (val instanceof Date) {
    date = val;
  } else if (typeof val === 'string' || typeof val === 'number') {
    date = new Date(val);
  }
  if (!date || isNaN(date.getTime())) return '';
  return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
}

export function KidsGallery() {
  const { rows, loading } = useRows('galleryPhotos', [where('isVisible', '==', true)]);
  const [activeIndex, setActiveIndex] = useState<number | null>(null);
  const [touchStartX, setTouchStartX] = useState<number | null>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);

  // Up to 12 visible photos, ordered by sortOrder
  const photos = [...(rows as GalleryPhoto[])]
    .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0))
    .slice(0, 12);

  // Keyboard navigation & body scroll lock for lightbox
  useEffect(() => {
    if (activeIndex === null) return;

    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        setActiveIndex(null);
      } else if (e.key === 'ArrowLeft') {
        setActiveIndex((prev) => (prev !== null && prev > 0 ? prev - 1 : photos.length - 1));
      } else if (e.key === 'ArrowRight') {
        setActiveIndex((prev) => (prev !== null && prev < photos.length - 1 ? prev + 1 : 0));
      }
    }

    window.addEventListener('keydown', handleKeyDown);
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = prevOverflow;
    };
  }, [activeIndex, photos.length]);

  // Sync native dialog
  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (activeIndex !== null && !dialog.open) {
      dialog.showModal();
    } else if (activeIndex === null && dialog.open) {
      dialog.close();
    }
  }, [activeIndex]);

  if (!loading && photos.length === 0) {
    return null;
  }

  if (photos.length === 0) {
    return null;
  }

  function handleTouchStart(e: React.TouchEvent) {
    setTouchStartX(e.touches[0].clientX);
  }

  function handleTouchEnd(e: React.TouchEvent) {
    if (touchStartX === null) return;
    const deltaX = e.changedTouches[0].clientX - touchStartX;
    const threshold = 40;
    if (deltaX > threshold) {
      // Swiped right -> previous
      setActiveIndex((prev) => (prev !== null && prev > 0 ? prev - 1 : photos.length - 1));
    } else if (deltaX < -threshold) {
      // Swiped left -> next
      setActiveIndex((prev) => (prev !== null && prev < photos.length - 1 ? prev + 1 : 0));
    }
    setTouchStartX(null);
  }

  const activePhoto = activeIndex !== null ? photos[activeIndex] : null;
  const activeDate = activePhoto ? formatMonthYear(activePhoto.createdAt) : '';

  return (
    <section className={styles.gallerySection} aria-labelledby="corner-wall-heading">
      <div className={styles.container}>
        <div className={styles.headingWrapper}>
          <h2 id="corner-wall-heading" className={styles.heading}>
            <span className={styles.headingLine1}>Our fighters,</span>
            <span className={styles.headingLine2}>in their corner.</span>
          </h2>
          <p className={styles.subheading}>Moments from training at the gym.</p>
        </div>

        <div className={styles.grid}>
          {photos.map((photo, index) => {
            const dateStr = formatMonthYear(photo.createdAt);
            const altText = photo.caption || 'Training at Junior Boy Boxing';

            return (
              <figure
                key={photo.id}
                className={styles.card}
                tabIndex={0}
                role="button"
                aria-label={photo.caption ? `View photo: ${photo.caption}` : 'View photo'}
                onClick={() => setActiveIndex(index)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    setActiveIndex(index);
                  }
                }}
              >
                <div className={styles.photoWrapper}>
                  <img
                    src={photo.imageUrl}
                    alt={altText}
                    loading="lazy"
                    className={styles.photo}
                  />
                </div>

                {photo.caption && (
                  <figcaption className={styles.cardCaption}>
                    <p className={styles.captionText}>{photo.caption}</p>
                    {dateStr && <p className={styles.dateText}>{dateStr}</p>}
                  </figcaption>
                )}
              </figure>
            );
          })}
        </div>
      </div>

      {/* Lightbox dialog */}
      <dialog
        ref={dialogRef}
        className={styles.lightbox}
        onCancel={() => setActiveIndex(null)}
        onClick={(e) => {
          if (e.target === dialogRef.current) {
            setActiveIndex(null);
          }
        }}
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
      >
        {activePhoto && (
          <div className={styles.lightboxContent}>
            <button
              type="button"
              className={styles.lightboxClose}
              aria-label="Close photo"
              onClick={() => setActiveIndex(null)}
            >
              ✕
            </button>

            {photos.length > 1 && (
              <>
                <button
                  type="button"
                  className={`${styles.lightboxNav} ${styles.lightboxPrev}`}
                  aria-label="Previous photo"
                  onClick={(e) => {
                    e.stopPropagation();
                    setActiveIndex((prev) =>
                      prev !== null && prev > 0 ? prev - 1 : photos.length - 1
                    );
                  }}
                >
                  ‹
                </button>
                <button
                  type="button"
                  className={`${styles.lightboxNav} ${styles.lightboxNext}`}
                  aria-label="Next photo"
                  onClick={(e) => {
                    e.stopPropagation();
                    setActiveIndex((prev) =>
                      prev !== null && prev < photos.length - 1 ? prev + 1 : 0
                    );
                  }}
                >
                  ›
                </button>
              </>
            )}

            <img
              src={activePhoto.imageUrl}
              alt={activePhoto.caption || 'Training at Junior Boy Boxing'}
              className={styles.lightboxImage}
            />

            {activePhoto.caption && (
              <div className={styles.lightboxCaption}>
                <p className={styles.lightboxCaptionText}>{activePhoto.caption}</p>
                {activeDate && <p className={styles.lightboxDateText}>{activeDate}</p>}
              </div>
            )}
          </div>
        )}
      </dialog>
    </section>
  );
}
