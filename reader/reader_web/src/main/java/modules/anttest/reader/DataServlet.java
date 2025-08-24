package modules.anttest.reader;

import modules.anttest.reader.ejb.RandomWordGeneratorRemote;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;
import java.nio.charset.StandardCharsets;

@WebServlet("/data")
public class DataServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        try {
            // Создаем контекст JNDI
            Context ctx = new InitialContext();

            String jndiName = "java:global/modules_anttest_reader/modules_anttest_reader_ejb/RandomWordGenerator!modules.anttest.reader.ejb.RandomWordGeneratorRemote";
            // Получаем удаленный интерфейс EJB
            RandomWordGeneratorRemote ejb = (RandomWordGeneratorRemote) ctx.lookup("java:/"+jndiName);

            // Вызов метода EJB
            String word = ejb.getWord();

            response.setContentType("application/json");
            response.setContentType("application/json; charset=windows-1251");
            response.setCharacterEncoding("windows-1251");
            try (OutputStream out = response.getOutputStream()) {
                String json = "[\"" + ejb.getWord() + "\", \"строка 2\", \"строка 3\"]";
                byte[] bytes = json.getBytes("windows-1251");
                out.write(bytes);
            }
        }catch (Exception e) {
            e.printStackTrace();
        }
    }


}