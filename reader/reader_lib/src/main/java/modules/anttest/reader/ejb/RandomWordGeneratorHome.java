package modules.anttest.reader.ejb;

import javax.ejb.EJBHome;

public interface RandomWordGeneratorHome extends EJBHome{
    
    public String getWord();
    
}