import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :wax_demo, WaxDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "rAzujdw+g13felgmvz+8r2axB7Fuo9MB4+ruu6iFHSA+0aka+PGiRExPOprrZkQQ",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
