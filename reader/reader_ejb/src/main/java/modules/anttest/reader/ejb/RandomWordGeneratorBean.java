package modules.anttest.reader.ejb;

import javax.ejb.SessionBean;
import javax.ejb.SessionContext;


public class RandomWordGeneratorBean implements SessionBean {

    private SessionContext ctx;

    public String getWord() {
        return "random-word";
    }

    // ������ ���������� �����
    public void ejbCreate() {
        // �������������, ���� �����
    }

    public void ejbActivate() {
        // ����������� ����
    }

    public void ejbPassivate() {
        // ������������ ����
    }

    public void ejbRemove() {
        // ������� ��������
    }

    public void setSessionContext(SessionContext ctx) {
        this.ctx = ctx;
    }
}
