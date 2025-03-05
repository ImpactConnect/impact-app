# Sermon Counters - Firestore Structure

## Collection: `sermons`
## Document ID: `[sermon_id]`

```json
{
  "title": "The Power of Faith",
  "preacherName": "Pastor John Doe",
  "category": "Faith",
  "tags": ["faith", "belief", "spiritual growth"],
  "thumbnailUrl": "https://example.com/thumbnails/sermon123.jpg",
  "audioUrl": "https://example.com/sermons/sermon123.mp3",
  "dateCreated": Timestamp.fromDate(new Date()),
  "clickCount": 42,
  "downloadCount": 15
}
```

The `clickCount` and `downloadCount` fields are automatically incremented when:
1. A user taps on a sermon to play it (increments `clickCount`)
2. A user downloads a sermon (increments `downloadCount`)

These counters are displayed on each sermon card in the sermon list, showing users how popular each sermon is.
