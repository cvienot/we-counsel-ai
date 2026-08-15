const stripeFactory = require('stripe');

const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;

const BRANDING = {
  business_profile: {
    name: 'Entrelace',
    product_description: 'AI-assisted couples coaching and communication support.',
    support_email: 'support@entrelace.app',
    support_url: 'https://entrelace.app',
    url: 'https://entrelace.app'
  },
  settings: {
    dashboard: {
      display_name: 'Entrelace'
    }
  }
};

function visibleAccountFields(account) {
  return {
    id: account.id,
    businessProfile: {
      name: account.business_profile?.name || null,
      productDescription: account.business_profile?.product_description || null,
      supportEmail: account.business_profile?.support_email || null,
      supportUrl: account.business_profile?.support_url || null,
      url: account.business_profile?.url || null
    },
    dashboardDisplayName: account.settings?.dashboard?.display_name || null
  };
}

async function updateAccount(stripe, accountId, includeDashboardName) {
  const params = includeDashboardName
    ? BRANDING
    : { business_profile: BRANDING.business_profile };

  return stripe.accounts.update(accountId, params);
}

async function main() {
  if (!STRIPE_SECRET_KEY) {
    throw new Error('STRIPE_SECRET_KEY must be set in the environment.');
  }

  const stripe = stripeFactory(STRIPE_SECRET_KEY);
  const account = await stripe.accounts.retrieve();

  console.log('Current Stripe branding:');
  console.log(JSON.stringify(visibleAccountFields(account), null, 2));

  let updated;
  try {
    updated = await updateAccount(stripe, account.id, true);
  } catch (error) {
    if (error?.type !== 'StripeInvalidRequestError') {
      throw error;
    }

    console.warn(
      `Could not update dashboard display name through this key (${error.message}). Retrying business profile only.`
    );
    updated = await updateAccount(stripe, account.id, false);
  }

  console.log('\nUpdated Stripe branding:');
  console.log(JSON.stringify(visibleAccountFields(updated), null, 2));
}

main().catch(error => {
  console.error('Failed to configure Stripe branding:', error.message);
  process.exit(1);
});
