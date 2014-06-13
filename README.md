# stackprof-remote

A Middleware and CLI for fetching and interacting with [StackProf](https://github.com/tmm1/stackprof) dumps.

## Description

stackprof-remote consists of a middleware for easy creation and retrieval of StackProf sampling profiler dumps from a remote machine, and a wrapper around pry (stackprof-cli) to create an interactive session for navigating dump files.

Currently, this is aimed at Rails apps running with unicorn, but there are options that should make it usable with any Rack app. In the future, I'd like to see it work with Resque and non-rack applications, too.

## Why

StackProf is amazing (BIG UPS TO @TMM1) but is not very operator friendly when it comes to collecting data about a current process. I was inspired by the [`go tool pprof` process](http://golang.org/pkg/net/http/pprof/) to make something that could wrap StackProf in an interface that should be as easy as including a middleware and pointing a bin at it to fetch and navigate a dump.

## Usage

1 - Add the Middleware to your app. 

``` ruby
# rails 2.3 style
require 'stackprof/remote/middleware'

# Should we enable stackprof-remote for this request.
# enabled can be a boolean or a proc that takes the Rack env hash
enabled = proc do |env|
  env['HOST_INFO'] =~ /private-hostname/ || Rails.env.development?
end
# Register the middleware
ActionController::Dispatcher.middleware.use StackProf::Remote::Middleware, enabled: enabled, logger: Rails.logger
```

2 - Run/restart your app.
3 - Attach to your application. 

``` bash
$ stackprof-remote localhost 
=== StackProf on localhost ===
Starting
[localhost] StackProf Started
Waiting for 30 seconds
[localhost] Results: 3023kb
Saved results to /home/paperless/.sp/sp-localhost-1402684964.dump
>>> sp-localhost-1402684964.dump loaded
stackprof> top 5
==================================
  Mode: cpu(1000)
  Samples: 5045 (3.28% miss rate)
  GC: 355 (7.04%)
==================================
     TOTAL    (pct)     SAMPLES    (pct)     FRAME
       736  (14.6%)         707  (14.0%)     ActiveSupport::LogSubscriber#start
       379   (7.5%)         379   (7.5%)     block in ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#execute
      5248 (104.0%)         168   (3.3%)     Benchmark#realtime
       282   (5.6%)         117   (2.3%)     ActiveSupport::LogSubscriber#finish
        88   (1.7%)          88   (1.7%)     block (2 levels) in Sass::Importers::Filesystem#find_real_file
```

## CLI

At the end of `stackprof-remote` it actually just enters a separate process `stackprof-cli`. This is a wrapper around [pry](https://github.com/pry/pry) that loads the dump file in an interactive session. It gives you a number of methods to interact with the dump:

* top N: show the top methods ordered by inner sample time.
* total N: show the top methods ordered by total time.
* all: Show all the methods ordered by sample time.
* method Name: show details about the callers and callees of Name

You can use `stackprof-cli` on its own by calling `stackprof-cli [dump-name]`

## Notes/Caveats

- You should use `enabled` on the Middleware to lock this down in production environments.
- Collecting dumps uses [`rbtrace`](https://github.com/tmm1/rbtrace) to execute the stackprof methods against the pool of unicorns running. If you're running something other than `unicorn` or you mess with the procline, you'll need to set the `:pid_finder` option.
- In order to get line level code output when using the `method` view you need to execute `stackprof-cli` in the same directory structure that your unicorn runs in. This doesn't necessarily mean the same server - we use remote dumps and inspect them in our local Vagrant environments that have the same directory structure.

## Requirements

Only works on MRI Ruby 2.1 (Upgrade already!). Its only been tested against Ruby 2.1.2 running on Linux (Centos 6.4). 

## Contributing to stackprof-remote
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2014 Aaron Quint. See LICENSE.txt for further details.

