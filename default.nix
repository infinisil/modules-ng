{
  /*

  */

  # Modules can do
  # - Declare new options
  # - Read options (via accessing config parameter)
  # - Write options (via setting config attribute)
  # - Import other modules and depend on other components components

  # Want to limit:
  # - What options can be written to/read from separately
  # - No need to limit declaring options as that can't influence much


  # meta.depends allows reading/writing to/from those modules options
  meta.depends = [ "nginx" ];
  # Defaults to [] or (all modules) if moduleVersion == 0
  meta.readDepends = [ "nginx" ]; # If nginx is allowed to be read from by parent
  meta.writeDepends = [ "nginx" ]; # If nginx is allowed to be written to by parent
  # Needs to be a subset of meta.*Restrict
  # These default to meta.depends if unset, with some smarts
  # These implicitly contain the current component

  # *Depends for speed (inferring them to be large is okay)
  # *Restrict for security (inferring them to be large is NOT okay)

  meta.restrict = [ "base" "nginx" ];
  # Defaults to the restrict set from the import parent
  meta.readRestrict = [ "base" "nginx" ];
  meta.writeRestrict = [ "base" "nginx" ];
  # These default to meta.restrict if unset

  # What if a component is a depends of two other components that have different restrict sets?
  # -> Take intersection of them

  # These readDepends/writeDepends/*restrict features don't need to be implemented initially, they can be added later on

  ## Naming:
  # With namespaces: rycee:home-manager
  # How to define namespaces?
  meta.namespace.nixpkgs = {
    components = {
      nginx = [ ./path/to/nginx/module.nix ];
      xorg = [ ./path/to/xorg/module.nix ];
    };

    options = {
      # This does:
      # - Allow implicit writeDepends for these options
      # - Restrict where the component can define options
      services.xserver._set = [ "xorg" ];

      services.xserver.display-manager._set = [ "dm" ];

      services.xserver.enable = [ "xorg" ];
    };
    # Why can't options be restricted somewhere else? Because we want to be able to use it for inferrence
  };
  # No default namespace. Only necessary to specify "nixpkgs:nginx" if conflict, otherwise "nginx" is enough
  # Wait no that's not good. If a component in nixpkgs depends on "base", but another namespace is imported that also defines "base", the user would have to change nixpkgs to refer to "nixpkgs:base".
  # So how about we default to the own namespace in case of conflicts
  # Or: All components from other namespaces need to explicitly refer to the namespace <- best one
  # Or: Define what other namespaces the current namespace can depend on. Nahh, this is handled by flakes
  # Or: Define a list of default namespaces. Nah, can still give unrecoverable ambiguous error

  # Security concern if nginx gets removed from nixpkgs and added somewhere else at the same time?
  # Can't have two namespaces named the same, error
  # Namespace has to be fully defined in a single file? Yes to make it simpler and to prevent other files from modifying it

  # imports are orthogonal to above modules. imports are there to have modularity within a single module. It extends the current module
  # An error should be produced if imports refers to a module that's not the same as the current one

  # New word to use for a collection of named modules: *component*. We can depend on components and such

  # Inter-namespace dependencies? Yes, should work by default

  meta.moduleVersion = 1;
  # meta.moduleVersion for backwards compatibility.
  # If module doesn't define any new meta attrs, default to 0
  # Otherwise default to 1
  # Error if new meta attrs are set but meta.moduleVersion = 0
  # Some time in the future this can be defaulted to 0 (by first going through a mandatory setting of this option?)

  # Can submodules still be implemented?
  # submodules should have unrestricted access again, completely new eval. They only define a new option after all, setting another option has to be done by the implementing component


  # How about a special "root"/null component (without a namespace). This is the root of everything, only this component can define namespaces or import other modules that define namespaces

  # configuration.nix file could look like this:
  configuration = {
    # This imports the nixpkgs namespace
    imports = [ <nixpkgs/nixos/modules> ];

    # Or writeDepends since we don't need read access
    meta.depends = [
      "nixpkgs:xorg"
    ];

    services.xserver.enable = true;

  };

  # Suggestion for meta.* naming: Never have two freeform keys in a row, e.g. allowing `usersettable.usersettable.bar = 10`. Use `usersettable.foo.usersettable.bar = 10` because then other attributes than foo can be added in the future if needed

  # Okay this is nice and all, but doesn't Flakes do something very much like that already? Flakes is more on the inter-repository level regarding dependencies. This is more on the intra-repository level (inside nixpkgs/nixos)

  # And even! We can integrate this idea perfectly with flakes:
  # Flakes can reserve the attribute `namespace` or so for defining their namespace! Each flake is a namespace defining options and stuff
  flake = {
    nixosNamespace = {
      components = {
        # ...
      };
      options = {
        # ...
      };
    };
    
  };

  # We need some way to force moduleVersion == 1 for all modules in order to ensure performance benefits
  # How about a meta.allowLegacy in the root component? Or how about meta.minimumModuleVersion?

  # Should we still have a meta.namespace thing then though? With this flakes approach, the root of a NixOS system would be a flake itself, defining the nixpkgs dependency and the configuration.nix. But if we want to allow people with the old approach to use namespaces a meta.namespaces might be needed. Although we could also *require* the flake approach to be used if people want the benefits

  /*
  All benefits are:
  - Faster evaluation time
  - Allow restricting what components can do in many ways
  - Integration with flakes, pure evaluation, caching of evaluation results?
  - Can be backwards-compatible

  Disadvantage:
  - readDepends can't be inferred and has to be specified. This needs to be done for all NixOS modules
  */

}
