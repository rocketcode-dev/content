# blog-content
blog content for capnajax.com

## Folders

| Folder  | Origin  | Transfer | Description |
| ------- | ------- | -------- | ----------- |
| draft   | desktop | sync     | Where new articles are written. This is synced to the server but not processed in any way. Move articles from `draft` to `ready` to publish them.
| ready   | desktop | backsync | Content that is ready for posting. New content from `drafts`, fixed content from `errors`, updates from `posted`, and reactivated content from `retired` all go here. This is synced to the server and processed. 
| errors  | server  | copy     | Content that was uploaded but could not be posted due to error. Edit the content and move it to the `ready` folder.
| posted  | server  | sync     | Content that has been posted. If you need to update it, make your changes and then move them `ready`. If you need to remove it, move it to `remove`
| retire  | desktop | backsync | Content that should be removed. 
| retired | server  | move     | Content that has been removed. Content can be republished by moving it back into the `ready` folder.

### Transfer types:

- `copy` means all files at the origin are copied to the destination.
- `move` means all files at the origin are copied to the destination and the destination does not keep a copy.
- `sync` means `copy`, but also delete any files at the destination that are not at the origin.
- `backsync` means `copy` but the destination will process these files and remove them from the origin.

### Workflows

#### Publishing new content

1. Create a folder in the `drafts` folder with the content. All content, including images and other media, should go in there.
1. Add a `meta.yaml` file so the publisher can track it and tag it correctly.
1. Edit the content in the `drafts` folder.
1. When ready, move the content to the `ready` folder.
1. Run the publisher.
1. Check the output for errors.
    1. If there are any errors, the content will be placed in the `errors` folder. If there are any, complete the [Fixing content errors](#fixing-content-errors) workflow.
    1. If there are no errors, the content will be placed in the `posted` folder.

#### Fixing content errors

1. Edit the content in the `errors` folder to remove all errors.
1. Move the entire content folder to the `ready` folder.
1. Run the publisher.
1. Check the output for errors.
    1. If there are any errors, the content will be placed back in the `errors` folder. Redo this workflow until all errors are resolved.
    1. If there are no errors, the content will be placed in the `posted` folder.

#### Updating existing content

1. Edit the content in the `posted` folder.
1. Move the entire content folder into the `ready` folder.
1. Run the publisher.
1. Check the output for errors.
    1. If there are any errors, the content will be placed in the `errors` folder. If there are any, complete the [Fixing content errors](#fixing-content-errors) workflow.
    1. If there are no errors, the content will be placed back in the `posted` folder.

#### Removing content

1. Move the entire content folder from `posted` to `retire`.
1. Run the publisher.
1. The content will be placed in the `retired` folder until deleted or reactivated.

#### Reactivating content

1. Move the entire content folder from `retired` to `ready`.
1. Check the output for errors.
    1. If there are any errors, the content will be placed in the `errors` folder. If there are any, complete the [Fixing content errors](#fixing-content-errors) workflow.
    1. If there are no errors, the content will be placed in the `posted` folder.

## Publisher

This is a process that reviews content in `ready`, updates the metadata, and publishes it.

Publishing steps:

1. rsync `drafts`, `ready`, and `retire` to the server. Use `--delete` for `drafts` but not for `ready` or `retire`.
1. Review all content in `retire` and, if any exists, unpublish it and move it to `retired`. Copy all new `retired` content back to the desktop.
1. Review all content in `ready` and for each item:
    1. Preprocess the content to ensure the metadata is accurate and update any fields necessary for the publish to work.
        1. If it can't be preprocessed, move it to the `error` folder, copy the error back to the desktop, and remove it from the desktop's `ready` folder.
        1. If it can be preprocessed, publish it, move it to the `posted` folder, and remove it from the `ready` folder. Sync the desktop's `ready` folder.
1. Report all errors and new publishing activity.
