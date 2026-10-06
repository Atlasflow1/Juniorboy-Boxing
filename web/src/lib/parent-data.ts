import { DateTime } from 'luxon';
import { Row } from './types';
import { asDate, zone } from './utils';

export const gymDate = (value: any) => DateTime.fromJSDate(asDate(value)).setZone(zone);
export const dayKey = (value: any) => gymDate(value).toISODate() || '';
export const upcomingOpen = (row: Row) => row.status === 'open' && row.offerStatus === 'published' && row.visibility === 'public' && +asDate(row.startAt) > Date.now();
export const seatsLeft = (row: Row) => Math.max(0, Number(row.capacity || 0) - Number(row.seatsTaken || 0));
export const stockFor = (product: Row, size?: string) => product.stock == null ? null : Number(product.stock[product.sizes?.length ? size || '' : 'default'] || 0);
export const soldOut = (product: Row) => product.stock != null && (product.sizes?.length ? product.sizes.every((s:string) => stockFor(product,s) === 0) : stockFor(product) === 0);
