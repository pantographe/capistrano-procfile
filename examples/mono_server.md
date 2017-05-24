# Example with one server

## Procfile

```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
websocket: bundle exec puma config/cable/config.ru -C config/cable/puma.rb
```


## Capistrano config

```ruby
# config/deploy/production.rb

server "myapp.com", user: "deploy", roles: %w{app web worker websocket}
```

## Conclusion

In this case, tree services will be generated on the same machine.  
And a systemd target will be generated too.
