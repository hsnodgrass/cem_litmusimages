# CEM Litmus Images

Easily and automatically generate and upload Docker images for use in Litmus tests.

## builder.rb

The script that holds the generation logic and CLI. Use `./builder.rb --help` to see all the options.

## build_specs

YAML files that are templates for the generated Dockerfiles / images.

### Build Spec Syntax

#### Required keys

- `FROM` - The value of this key is used directly in the `FROM` of the Dockerfile.
- `ENTRYPOINT` - Value can be a string or an array and the type changes the `ENTRYPOINT` form.
  - String values are created as shell form entry points in the Dockerfile
  - Array values are created as exec form entry points in the Dockerfile