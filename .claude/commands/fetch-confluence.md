# /fetch-confluence

Fetch a Confluence page by URL or page ID, convert HTML to markdown, and save to the repo.

## Usage
/fetch-confluence <url | page-id> [--dest <path>]

Default `--dest`: `architecture/legacy/`

## Behavior

1. **Load credentials** from `.env.acli.local`:
   - `ATLASSIAN_CONFLUENCE_USER`, `ATLASSIAN_CONFLUENCE_TOKEN`, `ATLASSIAN_CONFLUENCE_BASE_URL`
   - Halt if missing

2. **Extract page ID** from URL if URL provided

3. **Fetch page** via Confluence REST API:
   - `GET /wiki/rest/api/content/<id>?expand=body.storage,version,space`
   - Handle errors: 401 (auth failed), 403 (no access), 404 (page not found)

4. **Convert** HTML body to markdown:
   - Use embedded Python script for HTML→markdown conversion
   - Preserve tables, code blocks, headings

5. **Write** output file: `<dest>/<slug>.md`
   - YAML frontmatter: `title`, `confluence_id`, `space`, `last_updated`, `source`, `fetched`
   - If file exists: overwrite with warning

6. **Update context-index** (only for new files to default dest):
   - Add row to `architecture/context-index.md`
   - Skip on overwrite

## Reads
- `.env.acli.local`
- Confluence REST API

## Writes
- `<dest>/<slug>.md`
- `architecture/context-index.md` (new files to `architecture/legacy/` only)

## Notes
- Handles 401/403/404 with distinct error messages
- Overwrites existing file with warning
