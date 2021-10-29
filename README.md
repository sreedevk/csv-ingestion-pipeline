# GenreMatcher

GenreMatcher is an example implementation of Broadway Pipelines for CSV data ingestion & matching.
The sample CSV used here is a movie dataset that was downloaded from kaggle - https://www.kaggle.com/chaitanyahivlekar/large-movie-dataset

The application uses redis streams to communicate between pipelines and processes.

![1](https://user-images.githubusercontent.com/36154121/135732231-143db59e-6bb0-4211-b916-434ae97ab875.jpg)


Authors: Sreedev Kodichath, Joseph Giralt

## Setup

* Install asdf
[ASDF Documentation](http://asdf-vm.com/guide/getting-started.html#_1-install-dependencies)

* Install Language Servers + Compilers + Interpreters
``` sh
asdf install
```
Please note that the above command will install the following software on your system:

``` markdown
    - elixir 1.12.2-otp-24
    - erlang 24.0.5
    - postgres 13.2
    - nodejs 8.5.0
    - docker 20.10.8
```
* Install Elixir + Erlang Dependencies

``` sh
mix deps.get
```
* Install Phoenix

``` sh
mix local.hex                     # will install hex package manager
mix archive.install hex phx_new   # will install phoenix
```

* Edit `.envrc` with your local database creds
* Create Database

``` sh
mix ecto.create
```
* Run Migrations

``` sh
mix ecto.migrate
```
