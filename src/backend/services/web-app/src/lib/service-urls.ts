const internalGateway = process.env.INTERNAL_API_BASE_URL || '';

export const catalogApiBaseUrl =
  process.env.CATALOG_API_URL || `${internalGateway}/catalog`;
export const cartApiBaseUrl =
  process.env.CART_API_URL || `${internalGateway}/shoppingcart`;
export const checkoutApiBaseUrl =
  process.env.CHECKOUT_API_URL || `${internalGateway}/checkout`;
export const orderApiBaseUrl =
  process.env.ORDER_API_URL || `${internalGateway}/order`;
export const identityApiBaseUrl =
  process.env.IDENTITY_API_URL || internalGateway;
export const publicApiBaseUrl =
  process.env.PUBLIC_API_BASE_URL || internalGateway;
