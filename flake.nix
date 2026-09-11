{
  description = "eCloak — Zero-Knowledge Anonymous Chat for Logos Basecamp by Evice Labs";

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder";
    el_anon_chat_core.url = "github:evice-labs/el-anon-chat-core";
  };

  outputs = inputs@{ logos-module-builder, ... }:
    logos-module-builder.lib.mkLogosQmlModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
    };
}
