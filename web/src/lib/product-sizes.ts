export const SIZE_CATEGORIES: Record<string, string> = { clothing: 'Clothing', shoes: 'Shoes', equipment: 'Boxing Equipment' };
export const CLOTHING_SIZES = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
export const SHOE_SIZES = ['5', '5.5', '6', '6.5', '7', '7.5', '8', '8.5', '9', '9.5', '10', '10.5', '11', '11.5', '12', '13'];
export const EQUIPMENT_SIZES = ['8oz', '10oz', '12oz', '14oz', '16oz'];
export function sizesForCategory(category: string): string[] {
  if (category === 'clothing') return CLOTHING_SIZES;
  if (category === 'shoes') return SHOE_SIZES;
  if (category === 'equipment') return EQUIPMENT_SIZES;
  return [];
}
