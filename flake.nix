{
  outputs = { self } : {
    templates.java = {
      path = ./java;
      description = "default java shell";
    };

    templates.java-antlr = {
      path = ./java-antlr;
      description = "java shell with antlr parser generation";
    };
    
    templates.marimo = {
      path = ./marimo;
      description = "marimo shell for quick python stuff";
    };

    templates.python = {
      path = ./python;
      description = "default python shell";
    };
  };
}
