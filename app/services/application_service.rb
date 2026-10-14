# Base class for service and query objects: `Service.call(...)` is the only
# public entry point, so business operations are greppable by one convention.
class ApplicationService
  def self.call(...) = new(...).call
end
