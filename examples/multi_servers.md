# Example with many servers

## Procfile

```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
websocket: bundle exec puma config/cable/config.ru -C config/cable/puma.rb
```


## Capistrano config

```ruby
# config/deploy/production.rb

server "web1.myapp.com", user: "deploy", roles: %w{app web}
server "web2.myapp.com", user: "deploy", roles: %w{app web}
server "web3.myapp.com", user: "deploy", roles: %w{app web}

server "ws1.myapp.com", user: "deploy", roles: %w{app websocket}
server "ws2.myapp.com", user: "deploy", roles: %w{app websocket}

server "worker1.myapp.com", user: "deploy", roles: %w{app worker}
server "worker2.myapp.com", user: "deploy", roles: %w{app worker}
```

## Conclusion

In this case, on service per server will be generated (and a systemd target).  
So each web servers will only contain the web service. Websockets servers only contains websocket service.
