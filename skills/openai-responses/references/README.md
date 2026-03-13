# OpenAI Responses API – Official Links and Migration Pointers

This document compiles official OpenAI documentation and closely related official resources about the **Responses API** and places where OpenAI explicitly or implicitly guides developers to move off the older **Chat Completions** flow.

***

## Docs Index (TOC)

Browse the topic docs in this folder (relative paths):

* [MIGRATION\_FROM\_COMPLETIONS\_API.md](./MIGRATION_FROM_COMPLETIONS_API.md) — Migration guide from Chat/Completions to Responses
* [NEW\_IN\_RESPONSES.md](./NEW_IN_RESPONSES.md) — What’s new in Responses
* [text\_generation.md](./text_generation.md) — Simple text generation examples and tips
* [create\_vs\_parse.md](./create_vs_parse.md) — Create vs parse patterns and how to use `response_format`
* [structured\_outputs.md](./structured_outputs.md) — JSON schema structured outputs and best practices
* [tools\_web\_search.md](./tools_web_search.md) — Using built-in tools: web search
* [background\_jobs.md](./background_jobs.md) — Background/async jobs and polling
* [files\_api\_and\_uploads.md](./files_api_and_uploads.md) — Files API uploads and reference patterns
* [images\_vision.md](./images_vision.md) — Vision and image-input examples
* [audio\_speech.md](./audio_speech.md) — Transcription and speech notes
* [caching\_cost\_management.md](./caching_cost_management.md) — Caching, token control and cost management

## 1. Core Responses API Docs

1. **Responses API reference**\
   <https://platform.openai.com/docs/api-reference/responses>

2. **API reference introduction**\
   <https://platform.openai.com/docs/api-reference/introduction>

3. **Background / long-running Responses**\
   <https://platform.openai.com/docs/guides/background>

***

## 2. Main Guides That Prefer or Highlight Responses

These guides show Responses directly or contain language that it’s the preferred modern flow.

1. **Text generation** (explicitly recommends Responses over older Chat Completions)\
   <https://platform.openai.com/docs/guides/text>

2. **Conversation state** (explains Conversations + Responses pattern that replaces resending full history to chat)\
   <https://platform.openai.com/docs/guides/conversation-state>

3. **Agents / agent builder** (agentic flow built on the same primitives)\
   <https://platform.openai.com/docs/guides/agents/agent-builder>

4. **Using tools** (web search, file search, MCP, etc. from Responses)\
   <https://platform.openai.com/docs/guides/tools>

5. **File search (as a tool)**\
   <https://platform.openai.com/docs/guides/tools-file-search>

6. **Images & vision with Responses**\
   <https://platform.openai.com/docs/guides/images-vision>

7. **Audio & speech**\
   <https://platform.openai.com/docs/guides/audio>

8. **Structured outputs**\
   <https://platform.openai.com/docs/guides/structured-outputs>

9. **Advanced usage** (contains “Migrate to Responses API” style guidance)\
   <https://platform.openai.com/docs/advanced-usage>

10. **Flex processing**\
    <https://platform.openai.com/docs/guides/flex-processing>

***

## 3. Explicit Migration / Deprecation Signals Pointing to Responses

1. **Assistants → Responses migration guide**\
   <https://platform.openai.com/docs/assistants/migration>

2. **Deprecations page** (notes about moving to newer primitives, often Responses/Conversations)\
   <https://platform.openai.com/docs/deprecations/base-gpt-models>

3. **Models page** (many newer models are described as available via Responses)\
   <https://platform.openai.com/docs/models>

***

## 4. Official Announcements / Blog Posts About Responses

1. **Introducing / why the Responses API**\
   <https://developers.openai.com/blog/responses-api/>

2. **New tools and features in the Responses API**\
   <https://openai.com/index/new-tools-and-features-in-the-responses-api/>

3. **Community announcement: “Introducing the Responses API”**\
   <https://community.openai.com/t/introducing-the-responses-api/1140929>

4. **OpenAI Cookbook example using Responses**\
   <https://cookbook.openai.com/examples/responses_api/responses_example>

***

## 5. Minimum Set for an Internal “Migrate off Chat Completions” Note

Include at least these five to reflect the current official direction:

1. Text generation – <https://platform.openai.com/docs/guides/text>
2. Advanced usage – <https://platform.openai.com/docs/advanced-usage>
3. Conversation state – <https://platform.openai.com/docs/guides/conversation-state>
4. Tools – <https://platform.openai.com/docs/guides/tools>
5. Assistants migration – <https://platform.openai.com/docs/assistants/migration>

These five links, taken together, make the case that:

* new features land first in Responses,
* Conversation+Responses replaces the old “send entire message history to /v1/chat/completions” pattern,
* the modern tool story (web, file search, MCP) is designed around Responses,
* and OpenAI is actively publishing migration material that ends with “use Responses.”

***

*Last updated: 2025-11-09*
