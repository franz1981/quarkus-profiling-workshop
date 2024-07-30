package profiling.workshop.json;

import java.util.List;

import io.quarkus.resteasy.reactive.jackson.SecureField;

public class Customer extends Person {

    @SecureField(rolesAllowed = "admin")
    private double income;

    private Address address;

    private List<Person> children;

    private CreditCard[] creditCards;

    public double getIncome() {
        return income;
    }

    public void setIncome(double income) {
        this.income = income;
    }

    public Address getAddress() {
        return address;
    }

    public void setAddress(Address address) {
        this.address = address;
    }

    @Override
    public int getAge() {
        return super.getAge();
    }

    public List<Person> getChildren() {
        return children;
    }

    public void setChildren(List<Person> children) {
        this.children = children;
    }

    public CreditCard[] getCreditCards() {
        return creditCards;
    }

    public void setCreditCards(CreditCard[] creditCards) {
        this.creditCards = creditCards;
    }

    public String toJson() {
        return "{" +
                "\"firstName\":\""+ getFirstName() +
                "\",\"lastName\":\"" + getLastName() +
                "\",\"age\":" + getAge() +
                ",\"income\":" + income +
                "}";
    }
}
