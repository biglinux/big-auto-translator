"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OpenAITranslate = void 0;
const openai_1 = require("openai");
const util_1 = require("../util/util");
const lodash_1 = require("lodash");
async function translateSingleString(str, args) {
  var _a;
  const OPENAI_API_KEY = args.serviceConfig;
  if (!OPENAI_API_KEY || !OPENAI_API_KEY.trim().length) {
    (0, util_1.logFatal)('Missing OpenAI API Key: Please get an API key from https://platform.openai.com/account/api-keys and then call attranslate with --serviceConfig="YOUR API KEY"');
  }
  const configuration = new openai_1.Configuration({
    apiKey: OPENAI_API_KEY,
  });
  const openai = new openai_1.OpenAIApi(configuration);
  const messages = generateMessages(str, args);
  try {
    const completion = await openai.createChatCompletion({
      model: "gpt-4o-mini-2024-07-18",
      messages: messages,
      temperature: 0,
      max_tokens: 2048,
    });
    const text = completion.data.choices[0].message.content;
    if (text == undefined) {
      (0, util_1.logFatal)("OpenAI returned undefined for messages " + JSON.stringify(messages));
    }
    return text;
  } catch (e) {
    if (typeof e.message === "string") {
      (0, util_1.logFatal)("OpenAI: " +
        e.message +
        ", Status text: " +
        JSON.stringify((_a = e === null || e === void 0 ? void 0 : e.response) === null || _a === void 0 ? void 0 : _a.statusText));
    } else {
      throw e;
    }
  }
}
function generateMessages(str, args) {
  const capitalizedText = str;
  const systemMessage = {
    role: "system",
    content: `work as a text translator, only translate my software string from ${args.srcLng} to ${args.targetLng}. don't chat or explain. Using the correct terms for computer software in the target language, only show target language never repeat string. if you don't find something to translate, don't respond, string:`
  };  
  const userMessage = {
    role: "user",
    content: capitalizedText
  };
  return [systemMessage, userMessage];
}
async function translateBatch(batch, args) {
  console.log("Translate a batch of " + batch.length + " strings with OpenAI...");
  const promises = batch.map(async (tString) => {
    const rawResult = await translateSingleString(tString.value, args);
    const result = {
      key: tString.key,
      translated: rawResult.trim(),
    };
    return result;
  });
  const resolvedPromises = await Promise.all(promises);
  return resolvedPromises;
}
class OpenAITranslate {
  async translateStrings(args) {
    const batches = (0, lodash_1.chunk)(args.strings, 10);
    const results = [];
    for (const batch of batches) {
      const result = await translateBatch(batch, args);
      results.push(result);
    }
    return (0, lodash_1.flatten)(results);
  }
}
exports.OpenAITranslate = OpenAITranslate;
