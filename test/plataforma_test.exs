defmodule PlataformaTest do
  use ExUnit.Case

  defmodule Forwarder do
    use GenEvent

    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end

  @dets_file_name 'test_db.dets'
  @dets_alias :dets_alias

  setup do
    {:ok, notification} = GenEvent.start_link
    {:ok, dets} = :dets.open_file(@dets_alias, [file: @dets_file_name, type: :bag])

    {:ok, plataforma} = Plataforma.start_link(dets, notification, [])
    GenEvent.add_mon_handler(notification, Forwarder, self())

    on_exit fn ->
      :dets.close(dets)
      :file.delete(@dets_file_name)
    end

    {:ok, plataforma: plataforma}
  end

  test "validate create and lookup of subastas", %{plataforma: plataforma} do
    assert Plataforma.lookup_subasta(plataforma, "my_dummy_subasta") == :not_found

    Plataforma.create_subasta(plataforma, "my_dummy_subasta", 10, 20)
    {:ok, subasta} = Plataforma.lookup_subasta(plataforma, "my_dummy_subasta")
    assert subasta.name == "my_dummy_subasta"
    assert subasta.price == 10
    assert subasta.duration == 20
    assert subasta.offerer == :no_offered_yet
  end

  test "validate create and lookup of compradores", %{plataforma: plataforma} do
    assert Plataforma.lookup_comprador(plataforma, "my_dummy_comprador") == :not_found

    Plataforma.create_comprador(plataforma, "my_dummy_comprador", "dummy@comprador.com")
    {:ok, comprador} = Plataforma.lookup_comprador(plataforma, "my_dummy_comprador")
    assert comprador.name == "my_dummy_comprador"
    assert comprador.contacto == "dummy@comprador.com"
  end
end
