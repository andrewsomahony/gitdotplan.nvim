GitDotPlan Neovim Plugin
======================

## Introduction

This is a [Neovim](https://neovim.io/) plugin for [gitdotplan](https://github.com/andrewsomahony/gitdotplan)

## Installation

Simply install as normal with your favourite package manager.

### lazy.nvim

```
{
  "andrewsomahony/gitdotplan.nvim",
  opts = {
    repo_to_update={REPO_TO_UPDATE_URL}
  },
}
```

Where `REPO_TO_UPDATE_URL` is either a full git url (https://github.com/andrewsomahony/fingers.git) or
a short URL (andrewsomahony/fingers.git).

NOTE: You must have write access to the URL.

## Available Methods

### Fetch another user's .plan file

```
require("gitdotplan").finger(GIT_URL)
```

Where ```GIT_URL``` is in the same format as ```REPO_TO_UPDATE_URL```

### Open your .plan/.profile/.project for updating

```
require("gitdotplan").prepare_update(FILE_TO_UPDATE)
```

Where ```FILE_TO_UPDATE``` is one of 
* plan
* profile
* project

### Update your .plan file

```
require("gitdotplan").update()
```

