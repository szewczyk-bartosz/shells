{
  outputs = { self } : {
    templates.python = {
      path = ./python;
      description = "default python shell";
    };
  };
}
