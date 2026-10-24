use blog_manager::{
    publish::{GmbStatus, PublishRecord},
    repository::hash_revision,
};
#[test]
fn interrupted_gmb_is_unknown_and_keeps_operation_identity() {
    let temp = tempfile::tempdir().unwrap();
    let mut record = PublishRecord::new("note", "note.md", &hash_revision("input"));
    record.gmb = GmbStatus::InFlight;
    record.save(temp.path()).unwrap();
    let recovered = PublishRecord::recover(temp.path(), "note")
        .unwrap()
        .unwrap();
    assert_eq!(recovered.gmb, GmbStatus::Unknown);
    assert_eq!(recovered.operation_id, record.operation_id);
}
#[test]
fn corrupt_state_is_never_treated_as_a_new_operation() {
    let temp = tempfile::tempdir().unwrap();
    std::fs::write(temp.path().join("note.json"), "broken").unwrap();
    assert!(PublishRecord::load(temp.path(), "note").is_err());
}
#[test]
fn gmb_summary_is_plain_text_unicode_safe_and_uses_category_url() {
    let raw="---\ntitle: T\nslug: note\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://image.officeiko.work/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\n# 見出し\n**太字** [リンク](https://example.com)\n<post-image url=\"private\"/>\n";
    let p = blog_manager::repository::parse(raw).unwrap();
    let post = blog_manager::gmb::build_post(&p.front_matter, &p.body).unwrap();
    assert_eq!(post.call_to_action.url, "https://officeiko.co.jp/post/note");
    assert!(post.summary.contains("見出し"));
    assert!(!post.summary.contains("**"));
    assert!(!post.summary.contains("https://example.com"));
    assert!(!post.summary.contains("private"));
    let long = blog_manager::gmb::build_post(&p.front_matter, &"あ".repeat(2000)).unwrap();
    assert_eq!(long.summary.chars().count(), 1500);
}
#[test]
fn media_promotion_does_not_rewrite_prefix_collisions_or_plain_prose() {
    let raw="---\ntitle: T\nslug: note\npublishedOn: 2026-01-01\ncategory: blog\ntags: []\ncoverImage:\n  url: https://draft.test/blog/note/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\n";
    let mut p = blog_manager::repository::parse(raw).unwrap();
    let body="![yes](https://draft.test/blog/note/a.jpg) ![no](https://draft.test/blog/note/a.jpg-other) prose https://draft.test/blog/note/a.jpg";
    let changed = blog_manager::media::promote_urls(
        &mut p.front_matter,
        body,
        "https://draft.test",
        "https://public.test",
        &["blog/note/a.jpg".into()],
    );
    assert!(changed.contains("![yes](https://public.test/blog/note/a.jpg)"));
    assert!(changed.contains("![no](https://draft.test/blog/note/a.jpg-other)"));
    assert!(changed.ends_with("prose https://draft.test/blog/note/a.jpg"));
}
