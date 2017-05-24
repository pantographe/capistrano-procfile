# Capistrano::Procfile

**⚠️ This project is work in progress ⚠️**

Procfile specific tasks for Capistrano v3.  
This Capistrano v3 extension read the `Procfile` of your application to
generate `systemd` services.


## Installation

Add these lines to your application's Gemfile:

```ruby
group :development do
  gem "capistrano", "~> 3.6"
  gem "capistrano-procfile", "~> 1.2"
end
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install capistrano-procfile
```


## Usage

Require in `Capfile` to use the default task:

```ruby
require "capistrano/procfile"
```

This Capistrano extension reads the `Procfile` of your application and it generates `systemd` services.
The services generation is based on server roles to know which `Procfile` rules must be applied.
In each server a service target will be generated to simplify the availability of start/stop/restart a complete application.

Configurable options (default values):

```ruby
set :procfile_service_name,          -> { fetch(:application) }
set :procfile_service_path,          "/lib/systemd/system"
set :procfile_service_template_path, File.expand_path("../../templates/systemd", __FILE__)
set :procfile_service_env_vars,      {}
```


### Tasks

```
cap procfile:apply    # Apply Procfile commands on servers
...
```

All tasks except `procfile:apply` will exec `systemd` on the `.target` file.
That's mean


### Examples

See [examples](./examples/).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

This project is under MIT license.
