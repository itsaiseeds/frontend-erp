class AppStrings {
  AppStrings._();

  static const String APP_NAME = 'Saiseeds Sales';
  static const String APP_TAGLINE = 'Field sales, simplified';

  static const String ONBOARDING_SKIP = 'Skip';
  static const String ONBOARDING_NEXT = 'Next';
  static const String ONBOARDING_GET_STARTED = 'Get Started';

  static const String ONBOARDING_TITLE_1 = 'Welcome to Saiseeds';
  static const String ONBOARDING_BODY_1 =
      'Your complete sales companion for seed distribution, built for the field.';

  static const String ONBOARDING_TITLE_2 = 'Products at your fingertips';
  static const String ONBOARDING_BODY_2 =
      'Browse the full catalogue with live packaging and pricing, wherever you are.';

  static const String ONBOARDING_TITLE_3 = 'Track every order';
  static const String ONBOARDING_BODY_3 =
      'Record orders on the spot and keep your customers and territory organised.';

  static const String LOGIN_HEADING = 'Sales Portal Sign In';
  static const String LOGIN_SUBHEADING =
      'Enter your registered phone number and the 6-digit code from your authenticator app.';
  static const String LOGIN_PHONE_HINT = '10-digit mobile number';
  static const String LOGIN_OTP_HELPER = 'From your authenticator app';
  static const String LOGIN_SECURE_NOTE = 'Secured with time-based codes';
  static const String LOGIN_FAILED = 'Unable to sign in. Please try again.';
  static const String LOGIN_PHONE_REQUIRED = 'Phone number is required';
  static const String LOGIN_PHONE_INVALID = 'Enter a valid 10-digit number';
  static const String LOGIN_OTP_REQUIRED = 'Authentication code is required';
  static const String LOGIN_OTP_INVALID = 'Enter all 6 digits';

  static const String PHONE_NUMBER = 'Phone Number';
  static const String PHONE_COUNTRY_CODE_IN = '+91';
  static const String AUTHENTICATION_CODE = 'Authentication Code';
  static const String SIGN_IN = 'Sign In';

  static const String HOME_TITLE = 'Dashboard';
  static const String HOME_GREETING_PREFIX = 'Welcome back';
  static const String HOME_PLACEHOLDER_TITLE = 'Launching soon';
  static const String HOME_PLACEHOLDER_BODY =
      'This section is being built. It will be available in an upcoming release.';

  static const String DRAWER_SECTION_ACCOUNT = 'Account';
  static const String DRAWER_DASHBOARD = 'Dashboard';
  static const String DRAWER_PRODUCTS = 'Products';
  static const String DRAWER_ORDERS = 'Orders';
  static const String DRAWER_CLIENTS = 'Clients';
  static const String DRAWER_REPORTS = 'Reports';
  static const String DRAWER_PROFILE = 'Profile';

  static const String CLIENTS_TITLE = 'Clients';
  static const String CLIENTS_SELECT_CITY = 'Select city';
  static const String CLIENTS_CITY_LABEL = 'City';
  static const String CLIENTS_ALL_CITIES = 'All cities';
  static const String CLIENTS_SEARCH_NAME_HINT = 'Search company name';
  static const String CLIENTS_SEARCH_ADDRESS_HINT = 'Search address or city';
  static const String CLIENTS_SEARCH_SCOPE = 'Search by';
  static const String CLIENTS_CLEAR_SEARCH = 'Clear search';
  static const String CLIENTS_SCOPE_NAME = 'Company name';
  static const String CLIENTS_SCOPE_ADDRESS = 'Address';
  static const String CLIENTS_SEARCH_TOOLTIP = 'Search clients';
  static const String CLIENTS_EMPTY_TITLE = 'No clients found';
  static const String CLIENTS_EMPTY_BODY =
      'Try a different city or clear your search.';
  static const String CLIENTS_START_TITLE = 'Find your clients';
  static const String CLIENTS_START_BODY =
      'Pick a city and tap search to see the clients in that area.';
  static const String CLIENTS_ERROR_TITLE = 'Could not load clients';
  static const String CLIENTS_COUNT_ONE = 'client';
  static const String CLIENTS_COUNT_MANY = 'clients';
  static const String CLIENT_GST_LABEL = 'GST';
  static const String CLIENT_NO_GST = 'GST not registered';
  static const String CLIENT_ADDRESSES = 'Addresses';
  static const String CLIENT_CONTACTS = 'Contacts';
  static const String CLIENT_TRANSPORT = 'Transport';
  static const String CLIENT_CALL = 'Call';
  static const String CLIENT_MAIN = 'Main';
  static const String CLIENT_NO_ADDRESS = 'No address on file';

  static const String CLIENT_STATUS_VERIFIED = 'Verified';
  static const String CLIENT_STATUS_PENDING = 'Pending';
  static const String CLIENT_STATUS_UNKNOWN = 'Unknown';
  static const String CLIENT_VIEW_ALL = 'All';
  static const String CLIENTS_FILTERS = 'Filters';
  static const String CLIENTS_SORT = 'Sort';
  static const String CLIENTS_APPLY = 'Apply';
  static const String CLIENTS_SEARCH_FILTERS = 'Search across filters...';
  static const String CLIENTS_NO_FILTER_MATCH = 'No matching options';
  static const String CLIENTS_PICK_RANGE = 'Select a date range';
  static const String CLIENTS_CLEAR_DATES = 'Clear dates';
  static const String CLIENTS_CLEAR_ALL = 'Clear all';
  static const String CLIENTS_RESET = 'Reset';
  static const String CLIENTS_SORT_NEWEST = 'Newest first';
  static const String CLIENTS_SORT_OLDEST = 'Oldest first';
  static const String SORT_HIGHEST = 'Highest first';
  static const String SORT_LOWEST = 'Lowest first';
  static const String SORT_A_TO_Z = 'A to Z';
  static const String SORT_Z_TO_A = 'Z to A';
  static const String CLIENTS_DATE_FROM = 'From';
  static const String CLIENTS_DATE_TO = 'To';
  static const String CLIENTS_DATE_ANY = 'Any date';
  static const String CLIENTS_LOADING_MORE = 'Loading more';
  static const String CLIENT_VERIFIED_BY = 'Verified by';
  static const String CLIENT_CREATED_BY = 'Added by';
  static const String CLIENT_NO_CONTACT = 'No contact on file';

  static const String CLIENT_ADD_TITLE = 'New Client';
  static const String REQUIRED_MARKER = ' *';
  static const String OPTIONAL_SUFFIX = ' (optional)';
  static const String CLIENT_EDIT_TITLE = 'Edit Client';
  static const String CLIENT_EDIT_TOOLTIP = 'Edit client';
  static const String CLIENT_UPDATED = 'Client updated';
  static const String CLIENT_ADD_TOOLTIP = 'Add client';
  static const String CLIENT_STEP_DETAILS = 'Details';
  static const String CLIENT_STEP_ADDRESSES = 'Addresses';
  static const String CLIENT_STEP_CONTACTS = 'Contacts';
  static const String CLIENT_STEP_TRANSPORT = 'Transport';
  static const String CLIENT_STEP_PROGRESS = 'Step';
  static const String CLIENT_STEP_OF = 'of';

  static const String CLIENT_FIELD_NAME = 'Client Name';
  static const String CLIENT_FIELD_NAME_HINT = 'Registered business name';
  static const String CLIENT_FIELD_PHONE = 'Client Phone';
  static const String CLIENT_FIELD_GST = 'GST Number';
  static const String CLIENT_FIELD_GST_HINT = '15-character GSTIN';
  static const String CLIENT_FIELD_LINE1 = 'Address Line 1';
  static const String CLIENT_FIELD_LINE2 = 'Address Line 2';
  static const String CLIENT_FIELD_CITY = 'City';
  static const String CLIENT_FIELD_CITY_HINT = 'Select a city';
  static const String CLIENT_FIELD_PINCODE = 'Pincode';
  static const String CLIENT_FIELD_CONTACT_NAME = 'Contact Name';
  static const String CLIENT_FIELD_CONTACT_NAME_HINT = 'Person to reach';
  static const String CLIENT_FIELD_ROLE = 'Role';
  static const String CLIENT_FIELD_ROLE_HINT = 'Owner, Manager, Accounts';
  static const String CLIENT_FIELD_AGENCY_NAME_HINT = 'Transporter name';
  static const String CLIENT_FIELD_PHONE_OPTIONAL = 'Phone (optional)';
  static const String CLIENT_FIELD_LABEL = 'Label';
  static const String CLIENT_FIELD_LABEL_HINT = 'Head Office, Godown';
  static const String CLIENT_FIELD_LINE1_HINT = 'Building, street';
  static const String CLIENT_FIELD_LINE2_HINT = 'Area, landmark';
  static const String CLIENT_GROUP_LOCATION = 'Location';
  static const String CLIENT_GROUP_LABELLING = 'Labelling';
  static const String CLIENT_GROUP_DETAILS = 'Details';
  static const String CLIENT_FIELD_COUNTRY = 'Country';
  static const String CLIENT_FIELD_COUNTRY_HINT = 'Select a country';
  static const String CLIENT_FIELD_STATE = 'State';
  static const String CLIENT_FIELD_STATE_HINT = 'Select a state';
  static const String CLIENT_FIELD_STATE_LOCKED = 'Choose a country first';
  static const String CLIENT_FIELD_CITY_LOCKED = 'Choose a state first';
  static const String CLIENT_VALIDATION_STATE = 'Select a state';
  static const String GEO_UNAVAILABLE = 'Not available';
  static const String LOADING = 'Loading...';
  static const String CLIENT_FIELD_IS_MAIN = 'Main address';
  static const String CLIENT_FIELD_IS_MAIN_CONTACT = 'Main contact';
  static const String CLIENT_FIELD_IS_MAIN_TRANSPORT = 'Main transport agency';
  static const String CLIENT_FIELD_IS_MAIN_HINT =
      'Use this as the primary address for this client';
  static const String CLIENT_FIELD_IS_MAIN_LOCKED =
      'The first entry is always the main one';
  static const String CLIENT_MAIN_CONFLICT =
      'Only one entry can be marked as main. The previous one will be replaced.';
  static const String CLIENT_VALIDATION_MULTIPLE_MAIN =
      'Only one entry can be marked as main';
  static const String CLIENT_FIELD_AGENCY_NAME = 'Agency Name';

  static const String CLIENT_ADD_ADDRESS = 'Add address';
  static const String CLIENT_ADD_CONTACT = 'Add contact';
  static const String CLIENT_ADD_TRANSPORT = 'Add transport agency';
  static const String CLIENT_EDIT_ADDRESS = 'Edit address';
  static const String CLIENT_EDIT_CONTACT = 'Edit contact';
  static const String CLIENT_EDIT_TRANSPORT = 'Edit transport agency';
  static const String CLIENT_SET_MAIN = 'Set as main';
  static const String CLIENT_EDIT = 'Edit';
  static const String CLIENT_REMOVE = 'Remove';

  static const String CLIENT_NO_ADDRESSES_YET =
      'No addresses added yet. At least one is required.';
  static const String CLIENT_NO_CONTACTS_YET =
      'No contacts added yet. At least one is required.';
  static const String CLIENT_NO_TRANSPORT_YET =
      'No transport agencies added. This step is optional.';

  static const String CLIENT_VALIDATION_NAME = 'Client name is required';
  static const String CLIENT_VALIDATION_PHONE_REQUIRED =
      'Phone number is required';
  static const String CLIENT_VALIDATION_PHONE_INVALID =
      'Enter a valid 10-digit number';
  static const String CLIENT_VALIDATION_GST_REQUIRED = 'GST number is required';
  static const String CLIENT_VALIDATION_GST =
      'Enter a valid 15-character GST number';
  static const String CLIENT_VALIDATION_LINE1 = 'Address line 1 is required';
  static const String CLIENT_VALIDATION_CITY = 'Select a city';
  static const String CLIENT_VALIDATION_PINCODE =
      'Enter a valid 6-digit pincode';
  static const String CLIENT_VALIDATION_CONTACT_NAME =
      'Contact name is required';
  static const String CLIENT_VALIDATION_COUNTRY = 'Country is required';
  static const String CLIENT_VALIDATION_AGENCY_NAME = 'Agency name is required';
  static const String CLIENT_VALIDATION_NEED_ADDRESS =
      'Add at least one address to continue';
  static const String CLIENT_VALIDATION_NEED_CONTACT =
      'Add at least one contact to continue';

  static const String CLIENT_SAVE = 'Save Client';
  static const String CLIENT_SAVED = 'Client saved';
  static const String CLIENT_SAVE_FAILED = 'Could not save the client';
  static const String ENTRY_DISCARD_TITLE = 'Discard changes?';
  static const String ENTRY_DISCARD_BODY =
      'What you have entered here will not be saved.';
  static const String CLIENT_DISCARD_TITLE = 'Discard this client?';
  static const String CLIENT_DISCARD_BODY =
      'Everything you have entered will be lost.';
  static const String CLIENT_DISCARD_CONFIRM = 'Discard';
  static const String NEXT = 'Next';
  static const String BACK = 'Back';
  static const String ADD = 'Add';
  static const String SAVE_CHANGES = 'Save Changes';
  static const String SAVE = 'Save';

  static const String CLIENT_DETAIL_TITLE = 'Client';
  static const String CLIENT_DETAIL_NO_CONTACTS = 'No contacts on file';
  static const String CLIENT_DETAIL_NO_TRANSPORT =
      'No transport agencies on file';

  static const String LOGOUT = 'Logout';
  static const String LOGOUT_CONFIRM_TITLE = 'Sign out';
  static const String LOGOUT_CONFIRM_BODY =
      'You will need your authentication code to sign back in.';
  static const String CANCEL = 'Cancel';

  static const String SOMETHING_WENT_WRONG =
      'Something went wrong. Please try again.';
  static const String ERROR_NETWORK =
      'No internet connection. Check your network and try again.';
  static const String ERROR_TIMEOUT =
      'The request timed out. Please try again.';
  static const String ERROR_CANCELLED = 'The request was cancelled.';
  static const String ERROR_SERVER =
      'The server is unavailable right now. Please try again later.';
  static const String ERROR_FORBIDDEN =
      'You do not have permission to perform this action.';
  static const String ERROR_NOT_FOUND = 'The requested resource was not found.';
  static const String ERROR_RATE_LIMITED =
      'Too many attempts. Please wait a moment and try again.';
  static const String ERROR_UNEXPECTED_RESPONSE =
      'Received an unexpected response from the server.';
  static const String PACKETS_LABEL = 'packets';
  static const String KG_LABEL = 'kg';
  static const String TOTAL_LABEL = 'Total';
  static const String KG_UNIT = 'Kg';
  static const String PRODUCTS_TITLE = 'Products';
  static const String PRODUCTS_SEARCH_HINT = 'Search products';
  static const String PRODUCTS_EMPTY_TITLE = 'No products found';
  static const String PRODUCTS_EMPTY_BODY =
      'Try a different search or clear your filters.';
  static const String PRODUCTS_ERROR_TITLE = 'Could not load products';
  static const String PRODUCT_ADD = 'ADD';
  static const String PRODUCT_ADD_TO_CART = 'Add to cart';
  static const String PRODUCT_DETAIL_TITLE = 'Product';
  static const String CART_VIEW = 'View cart';
  static const String CART_ITEM = 'item';
  static const String CART_ITEMS = 'items';
  static const String CART_TITLE = 'Checkout';
  static const String CART_EMPTY_TITLE = 'Your cart is empty';
  static const String CART_EMPTY_BODY = 'Add products to place an order.';
  static const String CART_ORDER_SUMMARY = 'Order summary';
  static const String CART_TOTAL = 'Total';
  static const String CART_PLACE_ORDER = 'Place order';
  static const String CART_DELIVERY_TITLE = 'Delivery details';
  static const String CART_CONTINUE = 'Continue';
  static const String CART_SHIPMENT_TITLE = 'Your order';
  static const String CART_SHIPMENT_OF = 'Shipment of';
  static const String CART_DELIVERING_TO = 'Delivering to';
  static const String CART_SELECT_CLIENT = 'Client';
  static const String CART_SELECT_CLIENT_HINT = 'Select a client';
  static const String CART_SELECT_ADDRESS = 'Delivery address';
  static const String CART_SELECT_ADDRESS_HINT = 'Select an address';
  static const String CART_SELECT_AGENCY = 'Transport agency';
  static const String CART_SELECT_AGENCY_HINT = 'Select dispatch';
  static const String CART_PRIVATE_DISPATCH = 'Private dispatch';
  static const String CART_LOADING_OPTIONS = 'Loading...';
  static const String CART_NO_ADDRESSES = 'No saved address for this client';
  static const String CART_COMMENTS = 'Special comments';
  static const String CART_COMMENTS_HINT = 'Anything the team should know';
  static const String CART_ORDER_PLACED = 'Order placed';
  static const String VALIDATION_CLIENT_REQUIRED = 'Select a client.';
  static const String VALIDATION_ADDRESS_REQUIRED =
      'Select a delivery address.';
  static const String PRIMARY_BADGE = 'Main';
  static const String PRODUCT_PER_BAG = 'per bag';
  static const String IMAGE_ZOOM_HINT = 'Double tap or pinch to zoom';
  static const String PRODUCT_VIEW_IMAGE = 'View image';
  static const String PRODUCT_DESCRIPTION = 'Description';

  static const String ORDERS_EMPTY_TITLE = 'No orders yet';
  static const String ORDERS_EMPTY_BODY = 'Orders you book will appear here.';
  static const String ORDERS_ERROR_TITLE = 'Could not load orders';
  static const String ORDERS_COUNT_ONE = 'order';
  static const String ORDERS_COUNT_MANY = 'orders';

  static const String ORDER_STATUS_BOOKED = 'Booked';
  static const String ORDER_STATUS_UNDER_REVIEW = 'Under review';
  static const String ORDER_STATUS_CONFIRMED = 'Confirmed';
  static const String ORDER_STATUS_DISPATCHED = 'Dispatched';
  static const String ORDER_STATUS_DELIVERED = 'Delivered';
  static const String ORDER_STATUS_ON_HOLD = 'On hold';
  static const String ORDER_STATUS_REJECTED = 'Rejected';
  static const String ORDER_STATUS_UNKNOWN = 'Unknown';

  static const String ORDER_DETAIL_TITLE = 'Order details';
  static const String ORDER_ITEMS = 'Items';
  static const String ORDER_SUMMARY = 'Summary';
  static const String ORDER_DELIVERY = 'Delivery';
  static const String ORDER_BOOKED_ON = 'Booked on';
  static const String ORDER_EXPECTED_DELIVERY = 'Expected delivery';
  static const String ORDER_DISPATCH_MODE = 'Dispatch';
  static const String ORDER_DISPATCH_AGENCY = 'Transport agency';
  static const String ORDER_DISPATCH_PRIVATE = 'Own vehicle';
  static const String ORDER_TOTAL_AMOUNT = 'Total amount';
  static const String ORDER_TOTAL_PACKETS = 'Total packets';
  static const String ORDER_PRODUCTS_COUNT = 'Products';
  static const String ORDER_QUANTITY_PREFIX = 'Qty';
  static const String ORDER_PACKETS_SUFFIX = 'packets';
  static const String ORDER_BAGS_SUFFIX = 'bags';
  static const String ORDER_VERIFIED = 'Verified';
  static const String ORDER_VERIFIED_BY = 'Verified by';
  static const String ORDER_VERIFIED_ON = 'Verified on';
  static const String ORDER_AWAITING_VERIFICATION = 'Awaiting verification';
  static const String ORDER_VERIFICATION = 'Verification';
  static const String ORDER_LIST_PRICE = 'List price';
  static const String ORDER_AGREED_PRICE = 'Agreed';
  static const String ORDER_BAG_PRICE = 'per bag';
  static const String ORDER_LINE_TOTAL = 'Line total';
  static const String ORDER_MORE_PRODUCTS_PREFIX = '+';
  static const String ORDER_MORE_PRODUCTS_SUFFIX = 'more';
  static const String ORDER_DELIVERY_ADDRESS = 'Delivery address';
  static const String ORDER_NO_DATE = '--';
  static const String TIMEZONE_IST = 'IST';
  static const String ORDERS_SEARCH_HINT = 'Search client or product';
  static const String ORDERS_NO_MATCH_TITLE = 'No match';
  static const String ORDERS_NO_MATCH_BODY =
      'No client or product matches that name.';

  static const String SESSION_EXPIRED =
      'Your session has expired. Please sign in again.';
}
