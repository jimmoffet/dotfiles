# Tools & Web Search

This doc shows how to enable built-in web search and inspect tool-call outputs in Responses.

## Python SDK — enable web\_search

```python
from openai import OpenAI
client = OpenAI()

resp = client.responses.create(
    model="gpt-4o",
    input="Find the top 3 sources about the 2025 Python release notes and summarize.",
    tools=[{"type":"web_search"}],
    include=["web_search_call.action.sources"]
)

# The response will include web_search_call items and sources when included
print(resp.output)
```

## curl example

```bash
curl https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o","input":"Find the top 3 sources about the 2025 Python release notes and summarize.","tools":[{"type":"web_search"}],"include":["web_search_call.action.sources"]}'
```

## Notes

* Tool calls appear in the response object as typed items (e.g., `web_search_call`).
* Use `max_tool_calls` and `parallel_tool_calls` to control tool execution.
