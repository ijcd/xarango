defmodule DomainGraphTest do
  use ExUnit.Case
  doctest Xarango

  # alias Xarango.Domain.Graph
  
  setup do
    on_exit fn ->
      Xarango.Graph.__destroy_all()
      try do Xarango.Graph.__destroy_all(_database) rescue _ -> nil end
      Xarango.Collection.__destroy_all()
      try do Xarango.Collection.__destroy_all(_database) rescue _ -> nil end
    end
  end

  test "create graph" do
    graph = TestGraph.create
    assert length(graph.graph.edgeDefinitions) == 2
    assert length(graph.graph.orphanCollections) == 3
  end
  
  test "add relationships" do
    p1 = Person.create(%{name: "Alice"})
    p2 = Person.create(%{name: "Bob"})
    outback = Car.create(%{type: "Outback"})
    impreza = Car.create(%{type: "Impreza"})
    subaru = Brand.create(%{name: "Subaru"})
    likes = TestGraph.add_likes(p1, p2)
    has_brand = TestGraph.add_has_brand(outback, subaru)
    TestGraph.add_has_brand(impreza, subaru)
    assert String.starts_with?(likes._id, "likes/")
    assert String.starts_with?(has_brand._id, "has_brand/")
  end
  
  test "list relationships" do
    alice = Person.create(%{name: "Alice"})
    bob = Person.create(%{name: "Bob"})
    jim = Person.create(%{name: "Jim"})
    TestGraph.add_likes(alice, bob)
    TestGraph.add_likes(alice, jim)
    TestGraph.add_likes(bob, alice)
    alice_likes = TestGraph.likes_person(alice)
    alice_liked_by = TestGraph.person_likes(alice)
    assert length(alice_likes) == 2
    assert length(alice_liked_by) == 1
  end
  
  test "list db relationships" do
    alice = DbPerson.create(%{name: "Alice"})
    bob = DbPerson.create(%{name: "Bob"})
    jim = DbPerson.create(%{name: "Jim"})
    TestDbGraph.add_likes(alice, bob)
    TestDbGraph.add_likes(alice, jim)
    TestDbGraph.add_likes(bob, alice)
    alice_likes = TestDbGraph.likes_db_person(alice)
    alice_liked_by = TestDbGraph.db_person_likes(alice)
    assert length(alice_likes) == 2
    assert length(alice_liked_by) == 1
  end
  
  test "remove relationships" do
    alice = Person.create(%{name: "Alice"})
    bob = Person.create(%{name: "Bob"})
    TestGraph.add_likes(alice, bob)
    result = TestGraph.remove_likes(alice, bob)
    alice_likes = TestGraph.likes_person(alice)
    assert length(result) == 1
    assert Enum.at(result, 0)[:removed] == true
    assert length(alice_likes) == 0
  end

  test "remove db relationships" do
    alice = DbPerson.create(%{name: "Alice"})
    bob = DbPerson.create(%{name: "Bob"})
    TestDbGraph.add_likes(alice, bob)
    result = TestDbGraph.remove_likes(alice, bob)
    alice_likes = TestDbGraph.likes_db_person(alice)
    assert length(result) == 1
    assert Enum.at(result, 0)[:removed] == true
    assert length(alice_likes) == 0
  end

  test "create db graph" do
    graph = TestDbGraph.create
    assert length(graph.graph.edgeDefinitions) == 2
    assert length(graph.graph.orphanCollections) == 3
  end
  
  test "add db relationships" do
    outback = DbCar.create(%{type: "Outback"})
    impreza = DbCar.create(%{type: "Impreza"})
    subaru = DbBrand.create(%{name: "Subaru"})
    TestDbGraph.add_has_brand(outback, subaru)
    TestDbGraph.add_has_brand(impreza, subaru)
    subaru_cars = TestDbGraph.db_car_has_brand(subaru)
    outback_brands = TestDbGraph.has_brand_db_brand(outback)
    assert length(outback_brands) == 1
    assert length(subaru_cars) == 2
  end
  
  test "create vertex root graph" do
    graph = App.Graph.TestVrootGraph.create
    assert length(graph.graph.edgeDefinitions) == 2
    assert length(graph.graph.orphanCollections) == 3
  end
  
  defp _database do
    %Xarango.Database{name: "test_db"}
  end
end

defmodule Person, do: use Xarango.Domain.Node, graph: TestGraph
defmodule Car, do: use Xarango.Domain.Node, graph: TestGraph
defmodule Brand, do: use Xarango.Domain.Node, graph: TestGraph

defmodule TestGraph do
  use Xarango.Domain.Graph
  
  relationship Person, :likes, Person
  relationship Car, :has_brand, Brand

end

defmodule DbPerson, do: use Xarango.Domain.Node, graph: TestDbGraph, db: :test_db
defmodule DbCar, do: use Xarango.Domain.Node, graph: TestDbGraph, db: :test_db
defmodule DbBrand, do: use Xarango.Domain.Node, graph: TestDbGraph, db: :test_db


defmodule TestDbGraph do
  use Xarango.Domain.Graph, db: :test_db

  relationship DbPerson, :likes, DbPerson
  relationship DbCar, :has_brand, DbBrand

end

defmodule App.Graph.Nodes.Person, do: use Xarango.Domain.Node, graph: App.Graph.TestVrootGraph
defmodule App.Graph.Nodes.Car, do: use Xarango.Domain.Node, graph: App.Graph.TestVrootGraph
defmodule App.Graph.Nodes.Brand, do: use Xarango.Domain.Node, graph: App.Graph.TestVrootGraph

defmodule App.Graph.TestVrootGraph do
  use Xarango.Domain.Graph, db: :test_db
  
  alias App.Graph.Nodes
  
  relationship Nodes.Person, :likes, Nodes.Person
  relationship Nodes.Car, :has_brand, Nodes.Brand

end


