{
  description = "Zero-Knowledge Anonymous Chat with Cryptographic Moderation by Evice Labs";

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder";
    "e-cloak-core".url = "github:evice-labs/e-cloak-core";
  };

  outputs = inputs@{ logos-module-builder, ... }:
    logos-module-builder.lib.mkLogosQmlModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
    };
}
