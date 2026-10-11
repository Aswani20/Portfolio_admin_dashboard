import '../../models/content_validation.dart';

enum InputKind {
  text,
  paragraph,
  toggle,
  color,
  media,
  choices,
  strings,
  records,
}

/// Form presentation only. Persistence still uses the existing typed repositories.
class ContentField {
  const ContentField(
    this.name,
    this.label, {
    this.kind = InputKind.text,
    this.required = true,
    this.nullable = false,
    this.help,
    this.options = const [],
    this.children = const [],
    this.fixed = false,
    this.mediaKind,
    this.validator,
  });
  final String name, label;
  final InputKind kind;
  final bool required, nullable, fixed;
  final String? help, mediaKind;
  final List<String> options;
  final List<ContentField> children;
  final String? Function(String?)? validator;
}

const milestoneFields = [
  ContentField('title', 'Milestone title'),
  ContentField('duration', 'Duration'),
  ContentField(
    'type',
    'Milestone type',
    help: 'For example: Joined or Promotion',
  ),
  ContentField('highlights', 'Highlights', kind: InputKind.strings),
];
const experienceFields = [
  ContentField('role', 'Role'),
  ContentField('company', 'Company'),
  ContentField(
    'duration',
    'Duration',
    help: 'Keep the website display format, such as Jan 2024 - Present.',
  ),
  ContentField('location', 'Location'),
  ContentField('isCurrent', 'Current position', kind: InputKind.toggle),
  ContentField('highlights', 'Highlights', kind: InputKind.strings),
  ContentField(
    'milestones',
    'Career milestones',
    kind: InputKind.records,
    children: milestoneFields,
  ),
];
final certificateFields = [
  ContentField(
    'certificateUrl',
    'Certificate URL',
    nullable: true,
    required: false,
    validator: ContentValidation.url,
    help: 'Optional full https:// or http:// link. Clear to remove the certificate link.',
  ),
];
final educationFields = [
  const ContentField('degree', 'Degree / course'),
  const ContentField('institution', 'Institution'),
  const ContentField('duration', 'Duration'),
  const ContentField('location', 'Location'),
  const ContentField('isCurrent', 'Currently studying', kind: InputKind.toggle),
  ...certificateFields,
];
const skillFields = [
  ContentField('label', 'Technology name'),
  ContentField(
    'assetPath',
    'Technology icon',
    kind: InputKind.media,
    mediaKind: 'icon',
  ),
  ContentField('colorValue', 'Icon color (AARRGGBB)', kind: InputKind.color),
  ContentField(
    'themeAdaptive',
    'Adapt icon to light / dark theme',
    kind: InputKind.toggle,
  ),
];
const categoryFields = [
  ContentField('title', 'Category name'),
  ContentField(
    'skills',
    'Technologies',
    kind: InputKind.records,
    children: skillFields,
  ),
];
const detailFields = [
  ContentField('label', 'Label'),
  ContentField('value', 'Value', kind: InputKind.paragraph),
  ContentField(
    'icon',
    'Detail icon',
    kind: InputKind.choices,
    options: [
      'person_outline',
      'email_outlined',
      'phone_outlined',
      'location_on_outlined',
      'work_outline',
      'school_outlined',
    ],
  ),
];
final socialFields = [
  const ContentField('label', 'Social link label'),
  ContentField(
    'url',
    'Social URL',
    validator: (v) =>
        ContentValidation.requiredText(v) ?? ContentValidation.url(v),
  ),
  const ContentField(
    'iconPath',
    'Social icon',
    kind: InputKind.media,
    mediaKind: 'icon',
  ),
];
const targets = [
  'hero',
  'about',
  'skills',
  'projects',
  'education',
  'experience',
  'contact',
];
final profileFields = [
  const ContentField('name', 'Name'),
  const ContentField(
    'heroName',
    'Hero name (formatted)',
    help: 'Existing spaces, tab characters and quotes are preserved.',
  ),
  const ContentField('heroTitle', 'Hero title (formatted)'),
  const ContentField('tagline', 'Tagline', kind: InputKind.paragraph),
  const ContentField(
    'photoPath',
    'Profile photo',
    kind: InputKind.media,
    mediaKind: 'image',
  ),
  const ContentField('bio', 'About Me', kind: InputKind.paragraph),
  ContentField('email', 'Contact email', validator: ContentValidation.email),
  const ContentField('phone', 'Contact phone'),
  const ContentField('location', 'Contact location'),
  const ContentField(
    'personalDetails',
    'About details',
    kind: InputKind.records,
    children: detailFields,
    help: 'The website stores these separately from Contact. Edit both when changing shared information.',
  ),
  ContentField(
    'socialLinks',
    'Social media links',
    kind: InputKind.records,
    children: socialFields,
  ),
  const ContentField('primaryCtaLabel', 'Primary button label'),
  const ContentField(
    'primaryCtaTarget',
    'Primary button section',
    kind: InputKind.choices,
    options: targets,
  ),
  const ContentField('secondaryCtaLabel', 'Secondary button label'),
  const ContentField(
    'secondaryCtaTarget',
    'Secondary button section',
    kind: InputKind.choices,
    options: targets,
  ),
  const ContentField(
    'orbitIconPaths',
    'Hero orbit icons',
    kind: InputKind.strings,
    mediaKind: 'icon',
  ),
];
const settingsFields = [
  ContentField('brandName', 'Brand name'),
  ContentField('brandSuffix', 'Brand suffix', required: false),
  ContentField('appTitle', 'Application title'),
  ContentField('browserTitle', 'Browser title'),
  ContentField('description', 'Website description', kind: InputKind.paragraph),
  ContentField(
    'cvPath',
    'CV document',
    kind: InputKind.media,
    mediaKind: 'document',
  ),
  ContentField('cvLabel', 'CV download label'),
  ContentField(
    'cvDownloadFilename',
    'CV download filename',
    help: 'Existing formatting is preserved. This is a download name, not a local path.',
  ),
  ContentField(
    'navigationLabels',
    'Navigation labels',
    kind: InputKind.records,
    fixed: true,
    help: 'Existing website section identities and navigation order are retained.',
    children: [ContentField('label', 'Label')],
  ),
];
const sectionFields = [
  ContentField('heading', 'Heading'),
  ContentField(
    'subtitle',
    'Subtitle',
    kind: InputKind.paragraph,
    required: false,
  ),
];
