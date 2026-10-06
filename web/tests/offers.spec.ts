import { expect,test } from '@playwright/test';

test('signed-out offers routes render behind the admin shell',async ({page})=>{
  const errors:string[]=[];page.on('pageerror',error=>errors.push(error.message));
  for(const route of ['/admin/offers','/admin/offers/templates']){
    const response=await page.goto(route);
    expect(response?.status()).toBe(200);
    await expect(page.getByText('Sign in with an administrator account.')).toBeVisible();
    await expect(page.getByRole('link',{name:'Sign In'})).toBeVisible();
  }
  expect(errors).toEqual([]);
});
