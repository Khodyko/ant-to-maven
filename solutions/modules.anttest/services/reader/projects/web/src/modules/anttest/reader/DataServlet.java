package modules.anttest.reader;

import modules.anttest.reader.ejb.RandomWordGenerator;
import modules.anttest.reader.ejb.RandomWordGeneratorHome;
import modules.anttest.reader.ejb.RandomWordGeneratorRemote;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;

@WebServlet("/data")
public class DataServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
       
       try {
           // ������� �������� JNDI
           Context ctx = new InitialContext();

           String jndiName = "java:global/modules_anttest_reader/modules_anttest_reader_ejb/RandomWordGenerator!modules.anttest.reader.ejb.RandomWordGeneratorRemote";
           // �������� ��������� ��������� EJB
           RandomWordGeneratorRemote ejb = (RandomWordGeneratorRemote) ctx.lookup("java:/"+jndiName);

           // ����� ������ EJB
           String word = ejb.getWord();

           response.setContentType("application/json");
           response.setContentType("application/json; charset=windows-1251");
           response.setCharacterEncoding("windows-1251");
           try (OutputStream out = response.getOutputStream()) {
               String json = "[\"" + ejb.getWord() + "\", \"������ 2\", \"������ 3\"]";
               byte[] bytes = json.getBytes("windows-1251");
               out.write(bytes);
           }
       }catch (Exception e) {
           e.printStackTrace();
       }
    }


}