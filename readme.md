# Resume

Repository that holds the current version of my resume.

## How-To use

1. Update the necessary information in the resume, ensure to include the pdf update as well.
2. Execute the script:

    ```bash
    .\release.ps1 -ReleaseType "<major | minor | patch>" -CommitMessage "<add message here>"
    ```

3. Go to GitHub and do the release.

## Script process

```mermaid
    graph TB
    A((start)) --> B
    B(check git) --> C
    C(copy resume to OneDrive) --> D
    D(remove old archive) --> E
    E(create new archive) --> F
    F(get latest tag) --> G
    G(update tag) --> H
    H(stage changes) --> I
    I(commit changes) --> J
    J(tag new commit) --> K
    K(push new version to github) --> L
    L(push new tags) --> M
    M(create release in github) --> N
    N((end))

```
