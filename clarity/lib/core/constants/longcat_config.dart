const kLongcatApiKey = String.fromEnvironment(
  'LONGCAT_API_KEY',
  defaultValue: '',
);

const kLongcatChatCompletionsEndpoint = String.fromEnvironment(
  'LONGCAT_OPENAI_ENDPOINT',
  defaultValue: 'https://api.longcat.chat/openai/v1/chat/completions',
);

const kLongcatCrushModel = String.fromEnvironment(
  'LONGCAT_CRUSH_MODEL',
  defaultValue: 'LongCat-Flash-Omni-2603',
);

