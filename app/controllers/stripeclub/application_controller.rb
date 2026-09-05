module Stripeclub
  # Every screen in the engine. It inherits from the host's controller so the
  # host's door — whatever authentication it runs before an action — is the
  # engine's too, and the engine never has to know what a user is.
  class ApplicationController < Stripeclub.base_controller_class.constantize
  end
end
