# Rails + Postgres + AI Build

This is a tutorial presented at All Things Open 2023 to highligh how
easy it is to build a recommendation engine use OpenAI + Postgres + Ruby
on Rails.

Requirements are:

* Ruby 3.2.1
* Rails 7.1.1
* Postgres 16 w/ Vector Extension

If you don't have a Ruby installation, checkout [rbenv](https://github.com/rbenv/rbenv).

If you don't have a Postgres installation, checkout [Hombrew](https://brew.sh/) and run `brew install postgresql@16`.

To install the `vector` extension, you can clone the [pgvector](https://github.com/pgvector/pgvector) repo and run `make && make install`.  Then, you'll have access to the vector extension.

Once you have the requirements, run the following:

```
git clone <repo>
cd <repo>
```

Initialize Postgres:
```
initdb -D data
```

Run Postgres + Propshaft:
```
./bin/dev
```

Start Rails server in another terminal:
```
rails s
```

Open the URL printed from the above command in a browser.
