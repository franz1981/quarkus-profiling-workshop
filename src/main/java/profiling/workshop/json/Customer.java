package profiling.workshop.json;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.quarkus.resteasy.reactive.jackson.SecureField;

public class Customer extends Person {

    @SecureField(rolesAllowed = "admin")
    private double income;

    private Address address;

    @JsonProperty("children")
    private List<Person> persons;

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

    public List<Person> getPersons() {
        return persons;
    }

    public void setPersons(List<Person> persons) {
        this.persons = persons;
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
