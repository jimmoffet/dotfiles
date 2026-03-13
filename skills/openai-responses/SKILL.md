***

name: openai-responses
description: |
This skill provides concise, copy-pasteable Python SDK examples and integration guidance for the
OpenAI Responses API. It is intended to be used when migrating to or building with Responses
(text generation, structured outputs, tools, files/uploads, vision, audio, and background jobs).
license: See repository LICENSE.txt
-----------------------------------

# OpenAI Responses (skill)

When to use this skill

This skill should be used when authoring code, documentation, or integrations that target the
OpenAI Responses API and when Python SDK examples are needed. This skill should also be used
when migrating from legacy Chat/Completions flows to Responses.

How to use this skill (progressive disclosure)

* Load only the minimal metadata (this SKILL.md) to decide if the skill applies.
* If deeper details are required for a specific feature, load the single relevant file from the
  sibling `references/` folder (for example `./references/text_generation.md`).
* Prefer the `references/` documents for expanded examples, troubleshooting notes, and REST/curl
  equivalents — keep SKILL.md short and focused on actionable steps and Python SDK examples.

## Core guidance (imperative instructions)

* Describe the goal briefly, then run the minimal Python example below to confirm behavior.
* When invoking the SDK examples, supply a valid API key in the environment (e.g.,
  `OPENAI_API_KEY`).
* Use `prompt_cache_key`, `max_output_tokens`, and `temperature` to control cost and output.

## Examples (Python SDK only)

### 1) Text generation — quick example

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

resp = client.responses.create(
    model="gpt-4o",
    input=[{"type":"message","role":"user","content":[{"type":"input_text","text":"Write a friendly 2-sentence product blurb for a travel mug."}]}],
    max_output_tokens=120
)

print(resp.output[0].content[0].text)
```

See full guidance: ./references/text\_generation.md

### 2) Create vs parse (structured parsing)

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

schema = {
    "type": "object",
    "properties": {"name": {"type": "string"}, "email": {"type": "string"}},
    "required": ["name", "email"]
}

resp = client.responses.create(
    model="gpt-4o",
    input="Extract name and email from: 'Contact: Ada Lovelace <ada@example.com>'",
    response_format={"type":"json_schema","json_schema":{"name":"Contact","schema":schema}}
)

print(resp.output)
```

See full guidance: ./references/create\_vs\_parse.md and ./references/structured\_outputs.md

### 3) Tools — enable web search (tool call)

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

resp = client.responses.create(
    model="gpt-4o",
    input="Find the top two recent articles about Python performance improvements.",
    tools=[{"type":"web_search"}],
    include=["web_search_call.action.sources"]
)

# Inspect tool-call items in the response
print(resp.output)
```

See full guidance: ./references/tools\_web\_search.md

### 4) Background (long-running) jobs — start and poll

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

job = client.responses.create(
    model="gpt-4o",
    input="Perform an in-depth literature review on federated learning (may take minutes).",
    background=True
)

print('started:', job.id)

# Poll for completion later
status = client.responses.retrieve(job.id)
print('status:', status.status)
```

See full guidance: ./references/background\_jobs.md

### 5) Files & uploads — reference an uploaded file

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Pass an item reference to an uploaded file (replace file-abc123 with your file id)
resp = client.responses.create(
    model="gpt-4o",
    input=[
        {"type":"item_reference","id":"file-abc123"},
        {"type":"message","role":"user","content":[{"type":"input_text","text":"Summarize the attached document."}]}
    ]
)

print(resp.output)
```

See full guidance: ./references/files\_api\_and\_uploads.md

### 6) Images & vision — provide an image input

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

resp = client.responses.create(
    model="gpt-4o",
    input=[
        {"type":"message","role":"user","content":[{"type":"input_text","text":"Describe the image."}]},
        {"type":"input_image","image_url":"https://example.com/photo.jpg"}
    ]
)

print(resp.output)
```

See full guidance: ./references/images\_vision.md

### 7) Audio & speech — transcription or audio-aware flows

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# For long-form audio use the dedicated /v1/audio endpoints; this shows a simple Responses-style request
resp = client.responses.create(
    model="gpt-4o",
    input="Transcribe the attached audio and summarize key points.",
    # attach audio via file reference in production
)

print(resp.output)
```

See full guidance: ./references/audio\_speech.md

### 8) Caching & cost management — use prompt\_cache\_key and token controls

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

resp = client.responses.create(
    model="gpt-4o",
    input="Summarize these FAQs...",
    prompt_cache_key="faq_v1:summary",
    max_output_tokens=100
)

print(resp.usage)
```

See full guidance: ./references/caching\_cost\_management.md

References (progressive disclosure)

* The sibling `references/` folder contains the complete set of docs and extended examples. Load only the necessary file when more detail is required, for example:
  * `./references/MIGRATION_FROM_COMPLETIONS_API.md` — migration checklist and mapping examples
  * `./references/NEW_IN_RESPONSES.md` — summary of new features
  * `./references/text_generation.md`, `./references/create_vs_parse.md`, `./references/structured_outputs.md`, `./references/tools_web_search.md`, `./references/background_jobs.md`, `./references/files_api_and_uploads.md`, `./references/images_vision.md`, `./references/audio_speech.md`, `./references/caching_cost_management.md`

Grep search patterns (progressive disclosure aid)

If a consumer needs only a subset of the references (to keep context small), use these grep patterns to find the right files/sections before loading:

* web\_search|tools|file\_search
* response\_format|json\_schema|structured\_outputs
* background|long-running|background:true
* files|uploads|item\_reference
* image|vision|input\_image
* audio|transcription|speech
* prompt\_cache\_key|prompt\_cache

Implementation notes

* Keep examples minimal and runnable; prefer environment-based secrets (`OPENAI_API_KEY`).
* Validate `resp.output` and handle `incomplete_details` when using `response_format`.
* When using tools, inspect typed tool-call items in `resp.output` or request them via `include`.

Limitations and safety

* Do not embed secrets in prompts; pass sensitive files via the Files API and manage access controls.
* Respect rate limits and monitor `usage` to avoid unexpected costs.

***

End of SKILL.md
