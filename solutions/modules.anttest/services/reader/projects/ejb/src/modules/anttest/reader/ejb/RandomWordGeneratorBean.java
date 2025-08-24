package modules.anttest.reader.ejb;

import javax.ejb.SessionBean;
import javax.ejb.SessionContext;


public class RandomWordGeneratorBean implements SessionBean {

    private SessionContext ctx;

    public String getWord() {
        return "random-word";
    }

    // Методы жизненного цикла
    public void ejbCreate() {
        // Инициализация, если нужна
    }

    public void ejbActivate() {
        // Активизация бина
    }

    public void ejbPassivate() {
        // Пассивизация бина
    }

    public void ejbRemove() {
        // Очистка ресурсов
    }

    public void setSessionContext(SessionContext ctx) {
        this.ctx = ctx;
    }
}
