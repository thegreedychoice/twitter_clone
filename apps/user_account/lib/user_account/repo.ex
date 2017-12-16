"""
This is like a repository where all data can be accessed from anywhere in the application.
We can also connect this repository to our database and it acts as an interface between 
our database and the applicaton.
So, we can pass this data now to any controller that asks for it.
"""

defmodule UserAccount.Repo do
  use Ecto.Repo, otp_app: :user_account




  """
  The following code doesn't need Ecto

  def all(module) do
    users = [
      %UserAccount.User{
      id: 1,
      name: "Shubh Shukla",
      email: "shubh77@ufl.edu",
      password: "shubh",
      },
    %UserAccount.User{
      id: 2,
      name: "Srishti Mishra",
      email: "srishti@gmail.com",
      password: "srishti",
      },
    %UserAccount.User{
      id: 3,
      name: "Nienke",
      email: "nienke@gmail.com",
      password: "nienke",
      },
  ]
  end

  def get(module, id) do
    user = Enum.find(all(module), fn elem -> elem.id == id end)
  end

  """
end
