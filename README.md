# Slip

A minimal web framework that provides easy conveniences for authentication and authorization.

A sample endpoint
```
defmodule Actions do
  require Slip

  Slip.get("/project_name", :public) do
    %{status: 200, message: "Slip"}
  end
end
```
