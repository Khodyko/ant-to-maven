package modules.anttest.reader.ejb;

import javax.ejb.EJBObject;
import java.rmi.RemoteException;


public interface RandomWordGeneratorRemote extends EJBObject {

    String getWord() throws RemoteException;
}
