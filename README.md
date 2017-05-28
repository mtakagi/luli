# luli

[![License](http://img.shields.io/badge/license-APACHE2-blue.svg)](LICENSE)

## Overview

luli is a static analysis and linter tool for Lua.
luli enables you to detect various careful code can cause problems and unify coding style for projects or teams.
With it, you can shorten time to worry about coding style and fixing careless mistakes, and reduce cost for development and maintenance.

## About Coding Style

Now there are none of standard Lua coding styles.
luli prepares a coding style by referring to Python's PEP8.
Edit a configuration file to select warnings and errors for your projects.

## Building luli

luli supports Mac OS X and Ubuntu Linux.

These tools are required to build luli.
We recommend to using OPAM.

- OCaml 4.04.0
- OPAM 1.2.2
- OMake 0.9.8.6-0.rc1
- Core 113.33.02
- Menhir 20160825
- ucorelib 0.0.2

The following instructions are for building luli with OPAM.

### 1. Installing OCaml and OPAM

See [installation instructions](https://ocaml.org/docs/install.html).
Do not forget to specify OCaml version used by OPAM with `opam switch` command after OPAM installation, otherwise you may have trouble with version differences.

### 2. Installing the libraries

```
$ opam pin add omake 0.9.8.6-0.rc1
$ opam install core
$ opam install menhir
$ opam install ucorelib
```

### 5. Building luli

```
$ omake
```

## Installing luli 

Copy `luli` to your command path.

## Running the Tests

Required:

- Python 2.7.9 or later
- nose 1.3.7 or later

Execution:

```
$ omake test
```

## License

Copyright 2017 Shiguredo Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
