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
    "Deciding where to eat shouldn't be the hardest part of the day. Sa'n Tayo? was built for students who want good food that fits their budget, without the back-and-forth of \"saan ba tayo kakain?\" turning into twenty minutes of scrolling and second-guessing.\n\n"
    "Set your budget, pick what you're craving, and see what's actually nearby — real options from real local eateries around UCN, not a wall of ads or unrelated results. Sa'n Tayo? also gives small food businesses in the area a simple way to get discovered by the students who are already looking for exactly what they're serving.\n\n"
    "No clutter, no guesswork — just a faster way to answer the one question that starts every meal.";

const String about_credit = "Sa'n Tayo? — Developed by Kai Yaneza.";

const String password_requirements_hint =
    'be at least 8 characters, include a number, and not match your current password.';

const List<FaqItem> faq_items = [
  FaqItem(
    question: 'How do I find food near my campus?',
    answer: "Tap the search bar or browse \"Near you\" on the home screen. You can also set a default landmark under Profile > Default Landmark so results always start nearby.",
  ),
  FaqItem(
    question: 'Can I change my landmark or location?',
    answer: "Yes. Tap the location name at the top of the home screen, or go to Profile > Default Landmark, to switch to another landmark.",
  ),
  FaqItem(
    question: "Does Sa'n Tayo? track my GPS location?",
    answer: "No. Sa'n Tayo? uses landmarks you choose manually, not real-time GPS tracking.",
  ),
  FaqItem(
    question: "Can I order or pay for food through the app?",
    answer: "Not yet. Sa'n Tayo? currently helps you discover eateries and their menus — ordering and payment happen directly with the business.",
  ),
  FaqItem(
    question: "How do I list my food business on Sa'n Tayo?",
    answer: "Go to Profile and tap \"Switch to Business Account\" to get started.",
  ),
  // FaqItem(
  //   question: "I noticed wrong info on a listing — what do I do?",
  //   answer: "Use \"Contact Support\" below to report it, and we'll follow up with the business to get it corrected.",
  // ),
  FaqItem(
    question: "How do I change my password?",
    answer: "Go to Profile > Account > Change Password.",
  ),
  FaqItem(
    question: "Is my personal information safe?",
    answer: "Yes. See our Privacy Policy for details on what we collect and how it's protected.",
  ),
];

const LegalDocument terms_sections = LegalDocument(
  lastUpdated: 'September 2026',
  sections: [
    LegalSection(
      title: '1. Acceptance of Terms',
      body: "By creating an account or using Sa'n Tayo?, you agree to these Terms. If you do not agree, please don't use the app."
    ),
    LegalSection(
      title: "2. What Sa'n Tayo? Does",
      body: "Sa'n Tayo? helps students discover food stalls, carts, and small eateries near their campus or chosen landmark. Listings are submitted by food businesses and may change without notice."
    ),
    LegalSection(
      title: '3. User Accounts',
      body: "You're responsible for keeping your login credentials secure and for providing accurate information when registering."
    ),
    LegalSection(
      title: '4. Business Listings',
      body: "Business owners are responsible for the accuracy of their own menu, photos, and pricing. Sa'n Tayo? does not guarantee the accuracy, availability, or quality of any listed food or service."
    ),
    LegalSection(
      title: '5. No Ordering or Payment',
      body: "Sa'n Tayo? is currently for discovery purposes only. Orders, reservations, and payments are not processed through the app — any transaction happens directly between you and the business."
    ),
    LegalSection(
      title: '6. Prohibited Conduct',
      body: "Don't post false information, impersonate a business, or misuse the platform in a way that could harm other users."
    ),
    LegalSection(
      title: '7. Changes to the Service',
      body: "We may update, suspend, or discontinue features at any time as the app continues to develop."
    ),
    LegalSection(
      title: '8. Limitation of Liability',
      body: "Sa'n Tayo? is provided \"as is.\" We are not liable for any loss arising from your reliance on listing information."
    ),
    LegalSection(
      title: '9. Contact',
      body: "Questions about these Terms can be sent to support@santayo.app."
    ),
  ],
);

const LegalDocument privacy_sections = LegalDocument(
  lastUpdated: 'September 2026',
  sections: [
    LegalSection(
      title: "1. Information We Collect",
      body: "Your account details (name, email, contact number), your selected landmark preference, and basic usage data such as searches and filters used.",
    ),
    LegalSection(
      title: "2. How We Use Your Information",
      body: "To operate your account, personalize your browsing experience (like remembering your default landmark), and improve the app over time.",
    ),
    LegalSection(
      title: "3. Location Data",
      body: "Sa'n Tayo? uses landmark-based location, not GPS tracking. You choose your landmark manually, and we do not track your real-time location.",
    ),
    LegalSection(
      title: "4. Data Sharing",
      body: "We do not sell your personal information. Business owners never see your individual identity — only aggregated interest in their listings, where that feature is enabled.",
    ),
    LegalSection(
      title: "5. Data Security",
      body: "We take reasonable steps to protect your information, but no system can be guaranteed 100% secure.",
    ),
    LegalSection(
      title: "6. Your Rights",
      body: "You may request to update or delete your account information at any time by contacting support.",
    ),
    LegalSection(
      title: "7. Children's Privacy",
      body: "Sa'n Tayo? is intended for use by students under their school's applicable policies. We do not knowingly collect data from young children outside that context.",
    ),
    LegalSection(
      title: "8. Changes to this Policy",
      body: "We may revise this Policy as the app evolves. Continued use of Sa'n Tayo? means you accept the revised Policy.",
    ),
    LegalSection(
      title: "9. Contact",
      body: "Reach us at privacy@santayo.app for any privacy-related questions.",
    ),
  ],
);
