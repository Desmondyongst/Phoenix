# The show.ex file implements the LiveView module for a single product.
# It uses the show.html.heex template to render the HTML markup representing that product.
# I think this is when you click the product, not when you click edit as the edit part is handled by the modal part

defmodule PentoWeb.ProductLive.Show do
  use PentoWeb, :live_view

  alias Pento.Catalog
  alias PentoWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # I think this handle param is needed if you go the url directly, like
  # http://localhost:4000/products/2, so u need to populate the page with the correct product
  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    product = Catalog.get_product!(id)
    maybe_track_user(product, socket)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, product)
     |> assign(:own_message, "This is my own message!")}
  end

  # Pattern matching to ensure that the :live_action is :show

  def maybe_track_user(
        product,
        %{assigns: %{live_action: :show, current_user: current_user}} = socket
      ) do
    # Also, remember handle_params/3 will fire twice for a new page: once when the initial page loads and once when the page’s WebSocket connection is established.
    # We track after the socket is connected
    if connected?(socket) do
      Presence.track_user(self(), product, current_user.email)
    end
  end

  def maybe_track_user(_product, _socket), do: nil

  def handle_event("remove-upload", _params, %{assigns: %{product: product}} = socket) do
    case Catalog.remove_thumbnail_image(product) do
      {:ok, updated_product} ->
        {:noreply,
         socket
         # assigned the updated_product to the socket so it will rerender
         |> assign(:product, updated_product)
         |> put_flash(:info, "Image removed successfully!")}

      # Error message inside changeset
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error removing image!")}
    end
  end

  # NOTE: ref in this case is the image_id that is passed from the button
  # NOTE: We obtain the product from the socket as we are at the specific product page
  def handle_event(
        "remove-upload-product-images",
        %{"ref" => ref},
        %{assigns: %{product: product}} = socket
      ) do
    # ref is the id of the product_image of the prodict to be removed
    case Catalog.remove_product_images(product, ref) do
      {:ok, updated_product} ->
        {:noreply,
         socket
         # assigned the updated_product to the socket so it will rerender
         |> assign(:product, updated_product)
         |> put_flash(:info, "Image removed successfully!")}

      # Error message inside changeset
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error removing image!")}
    end
  end

  # Private function that is called in handle_params
  defp page_title(:show), do: "Show Product"
  defp page_title(:edit), do: "Edit Product"
end
