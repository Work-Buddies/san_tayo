// Static copy for profile sub-pages. Edit strings here only — screens read these lists.

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});
}

class LegalSection {
  final String title;
  final String body;

  const LegalSection({required this.title, required this.body});
}

class LegalDocument {
  final String lastUpdated;
  final List<LegalSection> sections;

  const LegalDocument({required this.lastUpdated, required this.sections});
}

const String app_version = '1.0.0';

const String about_body =
    "Sa'n Tayo? helps students discover food stalls, carts, and small eateries near their campus. "
    'Browse listings by landmark, search dishes and stalls, and save a default landmark so results always start close to you.';

const String password_requirements_hint =
    'be at least 8 characters, include a number, and not match your current password.';

const List<FaqItem> faq_items = [
  FaqItem(
    question: 'How do I find food near my campus?',
    answer:
        "Tap the search bar or browse 'Near you' on the home screen. You can also set a default landmark under Profile > Default Landmark so results always start nearby.",
  ),
  FaqItem(
    question: 'How do I change my default landmark?',
    answer:
        'Open Profile, tap Default Landmark, and pick a campus or landmark from the list. Your home feed and search filters use this pick.',
  ),
  FaqItem(
    question: 'How do I update my password?',
    answer:
        'Go to Profile > Change Password. Enter your current password, then choose a new one that meets the requirements shown on that screen.',
  ),
  FaqItem(
    question: 'Can I list my food business on Sa\'n Tayo?',
    answer:
        'Yes. From Profile, use Switch to Business Account if you have a user account. Business accounts can manage listings, menus, and photos (features may expand over time).',
  ),
  FaqItem(
    question: 'Why is my email not editable?',
    answer:
        'Your email is tied to sign-in and verification. Contact support if you need to change it — we may add self-service email updates later.',
  ),
];

const LegalDocument terms_sections = LegalDocument(
  lastUpdated: 'September 2026',
  sections: [
    LegalSection(
      title: '1. Acceptance of Terms',
      body:
          "By creating an account or using Sa'n Tayo?, you agree to these Terms. If you do not agree, do not use the app.",
    ),
    LegalSection(
      title: "2. What Sa'n Tayo? Does",
      body:
          "Sa'n Tayo? helps students discover food stalls, carts, and small eateries near their campus. Listings and menus are provided by business account holders; we do not guarantee accuracy, availability, or pricing.",
    ),
    LegalSection(
      title: '3. Your Account',
      body:
          'You are responsible for keeping your password secure and for activity under your account. You must provide accurate registration information and follow applicable laws when using the service.',
    ),
  ],
);

const LegalDocument privacy_sections = LegalDocument(
  lastUpdated: 'September 2026',
  sections: [
    LegalSection(
      title: '1. Information We Collect',
      body:
          'We collect account information you provide (such as email and username), usage data needed to operate the app, and optional location-related preferences like your saved default landmark.',
    ),
    LegalSection(
      title: '2. How We Use Information',
      body:
          'We use your information to authenticate you, personalize nearby results, improve the service, and communicate about your account when necessary.',
    ),
    LegalSection(
      title: '3. Sharing',
      body:
          'We do not sell your personal information. We may share data with service providers who help us run the app, or when required by law.',
    ),
  ],
);
