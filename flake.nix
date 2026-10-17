{
  outputs = { self } : {
    templates.java = {
      path = ./java;
      description = "default java shell";
    };

    templates.java-antlr = {
      path = ./java-antlr;
      description = "default java shell";
    };
    
    templates.python = {
      path = ./python;
      description = "default python shell";
    };
  };
}
