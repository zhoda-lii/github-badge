import pyodbc
import tkinter as tk
import tkinter.ttk as ttk
import matplotlib.pyplot as plt
import customtkinter
import datetime
from tkinter import messagebox
from tkinter import Button
from tkcalendar import Calendar

# SQL Server Path
sql_server = 'Server=ZHODA_LII\\SQLEXPRESS;'  # Change this to the server path
# Initialize calendar
cal = None

# Add Member Button: Main GUI
def open_insert_members():
    root = tk.Tk()
    root.title("Insert Member Data")
    root.geometry("295x220")

    # Function to insert member data into the database
    def insertMember():
        cursor = None
        try:
            # Connect to the database
            connection = pyodbc.connect('Driver={SQL Server};'+
                                sql_server+
                                'Database=GymProgressTracker;'+
                                'Trusted_Connection=True')

            # Get values from GUI fields
            firstname = entry_firstname.get()
            lastname = entry_lastname.get()
            dob = entry_dof.get()
            gender = entry_gender.get()
            email = entry_email.get()
            phonenumber = entry_phonenumber.get()
            print(gender)

            # Call the stored procedure with the values
            cursor = connection.cursor()
            cursor.execute("EXEC spAddMember ?, ?, ?, ?, ?, ?", 
                           firstname, lastname, gender, email, phonenumber, dob)

            # Commit the transaction
            connection.commit()

            # Print member ID
            cursor.execute(f"select MAX(MemberID) FROM Members")

            # Access the data with for loop
            for data in cursor: 
                pass

            messagebox.showinfo("Member Information", f"MemberID: {data[0]}\nName: {firstname} {lastname}\nDate Of Birth: {dob}")

        except Exception as e:
            messagebox.showerror("Error", f"Error occurred: {e}")

        finally:
            # Close the cursor and connection
            if cursor:
                cursor.close()
            if cursor:
                connection.close()
            # Close add member window
            root.destroy()

    # Function for date picker
    def get_date():
        date = cal.get_date()
        entry_dof.delete(0, tk.END)
        # print(date) # 2023-12-02 
        entry_dof.insert(0, date)
        top.destroy()

    # Function to show date picker calendar
    def show_calendar():
        global top
        top = tk.Toplevel(root)

        # Set min and max date
        current_date = datetime.datetime.now()
        default_date = current_date - datetime.timedelta(days=3650)  # 10 years before now
        min_date = current_date - datetime.timedelta(days=36525)  # 100 years before now
        max_date = current_date
        
        global cal
        cal = Calendar(top, selectmode="day", date_pattern='yyyy-mm-dd', mindate=min_date, maxdate=max_date, year=default_date.year, month=current_date.month, day=current_date.day )
        cal.pack(padx=10, pady=10)
        
        button_confirm = ttk.Button(top, text="Set Date of Birth", command=get_date)
        button_confirm.pack(pady=5)
    

    # GUI setup
    label_firstname = tk.Label(root, text="First Name:")
    entry_firstname = tk.Entry(root)

    label_lastname = tk.Label(root, text="Last Name:")
    entry_lastname = tk.Entry(root)

    label_dof = tk.Label(root, text="Date of Birth:")
    entry_dof = tk.Entry(root)
    # For date picker
    button_calendar = ttk.Button(root, text="▼", command=show_calendar, width=3)

    label_gender = tk.Label(root, text="Gender:")
    gender_var = tk.StringVar()
    entry_gender = ttk.Combobox(root, textvariable=gender_var, state="readonly", width=17)
    entry_gender["values"] = ("Male", "Female")
    entry_gender.current(0)

    label_email = tk.Label(root, text="Email:")
    entry_email = tk.Entry(root)

    label_phonenumber = tk.Label(root, text="Phone Number:")
    entry_phonenumber = tk.Entry(root)

    button_insert = ttk.Button(root, text="Add Member", command=insertMember)


    # Positioning
    label_firstname.grid(row=0, column=0, padx=10, pady=5)
    entry_firstname.grid(row=0, column=1, padx=10, pady=5)

    label_lastname.grid(row=1, column=0, padx=10, pady=5)
    entry_lastname.grid(row=1, column=1, padx=10, pady=5)

    label_dof.grid(row=2, column=0)
    entry_dof.grid(row=2, column=1)
    button_calendar.grid(row=2, column=2)

    label_gender.grid(row=3, column=0, padx=10, pady=5)
    entry_gender.grid(row=3, column=1, padx=10, pady=5)

    label_email.grid(row=5, column=0, padx=10, pady=5)
    entry_email.grid(row=5, column=1, padx=10, pady=5)

    label_phonenumber.grid(row=6, column=0, padx=10, pady=5)
    entry_phonenumber.grid(row=6, column=1, padx=10, pady=5)

    button_insert.grid(row=7, column=1, padx=10, pady=5)

    root.mainloop()

# Submit Payment Button: Main GUI
def open_payment_submission():
    # Function to check if member exist
    def is_member_exist():
        try:
            connection = pyodbc.connect('Driver={SQL Server};'+
                                    sql_server+
                                    'Database=GymProgressTracker;'+
                                    'Trusted_Connection=True')
            cursor = connection.cursor()

            cursor.execute(f"select * from Members where Memberid = {entry_member_id.get()}")

            # Access the data with a for loop
            data_found = False
            for _ in cursor:
                data_found = True

            return data_found
        
        except Exception as e:
            messagebox.showerror("Error", f"Error occurred: {e}")

        finally:
            if cursor:
                cursor.close()
            if connection:
                connection.close()

    # Function to submit payment data and update membership SQL
    def submit_payment():
        member_id = entry_member_id.get()
        if is_member_exist() == True and member_id != "":
            try:
                amount = entry_amount.get()
                payment_method = entry_payment_method.get()

                # Connect to the database
                connection = pyodbc.connect('Driver={SQL Server};'+
                                    sql_server+
                                    'Database=GymProgressTracker;'+
                                    'Trusted_Connection=True')

                cursor = connection.cursor()
                
                # Assuming the stored procedure parameters are in the correct order
                cursor.execute("EXEC spAddPaymentUpdateMembership ?, ?, ?", member_id, amount, payment_method)

                connection.commit()

                print("Success", "Payment added and membership updated successfully!")
                messagebox.showinfo("Success", "Payment added and membership updated successfully!")

            except Exception as e:
                messagebox.showerror("Error", f"Error occurred: {e}")

            finally:
                if cursor:
                    cursor.close()
                if connection:
                    connection.close()
                # Close window
                root.destroy()
        else:
            messagebox.showerror("No Data", "Member ID does not exist.")

    # Function for auto update of payment amount field
    def update_payment_amount(event):
        selected_memtype = entry_type.get()
        if selected_memtype == "Standard":
            entry_amount.configure(state="normal")
            entry_amount.delete(0, tk.END)
            entry_amount.insert(0, 50)
            entry_amount.configure(state="readonly")
        elif selected_memtype == "Premium":
            entry_amount.configure(state="normal")
            entry_amount.delete(0, tk.END)
            entry_amount.insert(0, 100)
            entry_amount.configure(state="readonly")

    root = tk.Tk()
    root.title("Add Payment and Update Membership")

    label_member_id = tk.Label(root, text="Member ID:")
    label_member_id.grid(row=0, column=0, padx=10, pady=5)
    entry_member_id = tk.Entry(root)
    entry_member_id.grid(row=0, column=1, padx=10, pady=5)

    label_type = tk.Label(root, text="Membership Type:")
    label_type.grid(row=1, column=0, padx=10, pady=5)
    memtype_var = tk.StringVar()
    entry_type = ttk.Combobox(root, textvariable=memtype_var, state="readonly", width=17)
    entry_type["values"] = ("Standard", "Premium")
    entry_type.current(0)
    entry_type.grid(row=1, column=1, padx=10, pady=5)
    entry_type.bind("<<ComboboxSelected>>", update_payment_amount)

    label_payment_method = tk.Label(root, text="Payment Method:")
    method_var = tk.StringVar()
    entry_payment_method = ttk.Combobox(root, textvariable=method_var, state="readonly", width=17)
    entry_payment_method["values"] = ("Cash", "Debit Card", "Credit Card")
    entry_payment_method.current(0)
    entry_payment_method.grid(row=2, column=1, padx=10, pady=5)
    label_payment_method.grid(row=2, column=0, padx=10, pady=5)

    label_amount = tk.Label(root, text="Payment Amount:")
    entry_amount = tk.Entry(root)
    entry_amount.insert(0, 50)
    entry_amount.configure(state="readonly")
    label_amount.grid(row=3, column=0, padx=10, pady=5)
    entry_amount.grid(row=3, column=1, padx=10, pady=5)

    button_submit = ttk.Button(root, text="Submit Payment", command=submit_payment)
    button_submit.grid(row=4, columnspan=2, padx=10, pady=5)

    root.mainloop()

# Add Fitness Record Button: Main GUI
def open_insert_record():
    # Function to insert fitness record data into the database SQL
    def insertData():
        cursor = None
        try:
            # Connect to the database
            connection = pyodbc.connect('Driver={SQL Server};'+
                                sql_server +
                                'Database=GymProgressTracker;'+
                                'Trusted_Connection=True')

            # Get values from GUI fields
            memberid = entry_memberid.get()
            calorieintake = entry_calorieintake.get()
            weight_lbs = entry_weight_lbs.get()
            height = entry_height.get()

            # Convert necessary values to appropriate types
            memberid = int(memberid)  # Assuming memberid is an integer
            calorieintake = float(calorieintake)  # Assuming calorieintake is an integer
            weight_lbs = float(weight_lbs)  # Assuming weight_lbs is a float
            height = float(height)  # Assuming height is a float
            
            # Check if the member ID exists
            cursor = connection.cursor()
            cursor.execute("SELECT MemberID FROM Members WHERE MemberID = ?", memberid)
            if not cursor.fetchone():
                messagebox.showerror("Error", f"Member ID {memberid} does not exist.")
                return
            
            # Call the stored procedure with the values
            cursor.execute("EXEC spAddFitnessRecord ?, ?, ?, ?", 
                        memberid, calorieintake, weight_lbs, height)  # Changed variable name

            # Commit the transaction
            connection.commit()

            # Display a pop-up notification for successful insertion
            messagebox.showinfo("Success", "Record added successfully!")
            root.destroy()

        except Exception as e:
            messagebox.showerror("Error", f"Error occurred: {e}")

        finally:
            # Close the cursor and connection
            if cursor:
                cursor.close()
            if connection:
                connection.close()

    # GUI setup for inserting fitness record
    root = tk.Tk()
    root.title("Insert Fitness Record")

    label_memberid = tk.Label(root, text="Member ID:")
    entry_memberid = tk.Entry(root)

    label_calorieintake = tk.Label(root, text="Calorie Intake:")
    entry_calorieintake = tk.Entry(root)

    label_weight_lbs = tk.Label(root, text="Weight (Lbs):")
    entry_weight_lbs = tk.Entry(root)

    label_height = tk.Label(root, text="Height (Inches):")
    entry_height = tk.Entry(root)

    button_insert = ttk.Button(root, text="Add Fitness Record", command=insertData)

    label_memberid.grid(row=1, column=0, padx=10, pady=5)
    entry_memberid.grid(row=1, column=1, padx=10, pady=5)

    label_calorieintake.grid(row=2, column=0, padx=10, pady=5)
    entry_calorieintake.grid(row=2, column=1, padx=10, pady=5)

    label_weight_lbs.grid(row=3, column=0, padx=10, pady=5)
    entry_weight_lbs.grid(row=3, column=1, padx=10, pady=5)

    label_height.grid(row=4, column=0, padx=10, pady=5)
    entry_height.grid(row=4, column=1, padx=10, pady=5)

    button_insert.grid(row=6, columnspan=2, padx=10, pady=5)

    root.mainloop()

# View Member Button: Main GUI
def open_membership_checker():
    # Function to select member ID
    def select():
        try:
            connection = pyodbc.connect('Driver={SQL Server};'+
                                    sql_server+
                                    'Database=GymProgressTracker;'+
                                    'Trusted_Connection=True')
            cursor = connection.cursor()

            cursor.execute(f"select * from Members where Memberid = {entry_id.get()}")

            # Access the data with a for loop
            data_found = False
            for data in cursor:
                info_label.configure(
                    text=f"Name: {data[1]} {data[2]}\n"
                         f"Membership Type: {data[9]}\n"
                         f"Membership Start: {data[7]}\n"
                         f"Membership End: {data[8]}"
                )
                data_found = True

            if not data_found:
                messagebox.showerror("No Data Found", "No member with the given ID was found.")

        except Exception as e:
            messagebox.showerror("Error", f"Error occurred: {e}")

        finally:
            if cursor:
                cursor.close()
            if connection:
                connection.close()

    app = tk.Tk()
    app.title('Membership Checker')
    # app.geometry("250x250")  # Adjust the size of the window

    # Entry object
    entry_table_name = tk.Label(app, text="Enter Member ID:")
    # entry_id = customtkinter.CTkEntry(app, placeholder_text="ID")
    entry_id = tk.Entry(app)

    # Label to display information
    info_label = tk.Label(app, text="")
    select_button = ttk.Button(app, text="View Member", command=select)

    entry_table_name.grid(row=1, column=0, padx=10, pady=5)
    entry_id.grid(row=2, column=0, padx=10, pady=5)
    select_button.grid(row=3, column=0, padx=10, pady=5)
    info_label.grid(row=4, column=0, padx=10, pady=5)

    app.mainloop()

# View Fitness Record Button: Main GUI
def open_member_data_viewer():
    # Function to show weight trend
    def show_weight_trend(rows):
        # Extracting data for plotting
        dates = [row[1] for row in rows]
        weights = [row[8] for row in rows]

        # Determine the step size for the x-axis ticks
        step = max(len(dates) // 5, 1)

        # Creating the line graph
        plt.figure(figsize=(10, 6))
        plt.plot(dates, weights, marker='o', linestyle='-')
        plt.title("Weight Trend")
        plt.xlabel("Date")
        plt.ylabel("Weight (lbs)")
        plt.xticks(dates[::step], rotation=45)  # Set x-axis ticks with step size
        plt.ylim(65, 250)  # Set y-axis limits
        plt.grid(True)
        plt.tight_layout()
        plt.show()
        
    # Function to view member data
    def view_member_data():
        try:
            member_id = entry_member_id.get()
            connection = pyodbc.connect('Driver={SQL Server};'+ sql_server + 'Database=GymProgressTracker;' + 'Trusted_Connection=True')
            cursor = connection.cursor()
            cursor.execute('SELECT * FROM vwTrainerNutritionTraining WHERE MemberID = ?', member_id)
            rows = cursor.fetchall()  # Fetch all rows instead of just one
            
            if rows:
                view_window = tk.Tk()
                view_window.title(f"Member Data for Member ID: {member_id}")

                # Define columns
                column_names = [cursor.description[i][0] for i in range(len(cursor.description))]
                visible_columns = column_names[1:]  # Exclude the first column
                # print(column_names)

                tree = ttk.Treeview(view_window, columns=visible_columns, show="headings")

                # Configure vertical scrollbar
                vsb = ttk.Scrollbar(view_window, orient="vertical", command=tree.yview)
                vsb.pack(side="right", fill="y")
                tree.configure(yscrollcommand=vsb.set)

                # Configure horizontal scrollbar
                hsb = ttk.Scrollbar(view_window, orient="horizontal", command=tree.xview)
                hsb.pack(side="bottom", fill="x")
                tree.configure(xscrollcommand=hsb.set)

                for col in visible_columns:
                    tree.heading(col, text=col)
                    # Adjust column width based on content
                    max_width = max([len(str(row[i])) for row in rows for i in range(1, len(row)) if isinstance(row[i], (int, float))] + [len(col)])
                    tree.column(col, width=max_width * 10)  # Adjust based on content length

                for row in rows:  # Insert each row into the Treeview, excluding the first column
                    formatted_row = [round(value, 2) if isinstance(value, float) else value for value in row[1:]]  # Exclude the first column
                    tree.insert("", "end", values=formatted_row)
                
                tree.pack(expand=True, fill="both")

                # Function to display the line graph
                def show_graph():
                    show_weight_trend(rows)

                # Button to display the line graph
                btn_show_graph = Button(view_window, text="Show Weight Trend Graph", command=show_graph)
                btn_show_graph.pack()

                view_window.mainloop()
            else:
                messagebox.showerror("No Data", "No data found for the provided Member ID.")

        except Exception as e:
            messagebox.showerror("Error", f"Error occurred: {e}")

        finally:
            if cursor:
                cursor.close()
            if connection:
                connection.close()


    root = tk.Tk()
    root.title("Member Data Viewer")
    root.geometry("200x100")

    member_id_label = tk.Label(root, text="Enter Member ID:")
    member_id_label.pack(pady=5)
    entry_member_id = tk.Entry(root)
    entry_member_id.pack(pady=5)

    view_button = tk.Button(root, text="View Fitness Record", command=view_member_data)
    view_button.pack(pady=5)

    root.mainloop()

# Function to open the Main GUI Window
def open_main_window():
    main_screen = customtkinter.CTk()
    main_screen.geometry("300x200")
    main_screen.title('Gym Progress Tracker')

    insert_members_button = customtkinter.CTkButton(main_screen, text="Add Member", command=open_insert_members)
    insert_members_button.place(relx=0.27, rely=0.1)

    payment_button = customtkinter.CTkButton(main_screen, text="Submit Payment", command=open_payment_submission)
    payment_button.place(relx=0.27, rely=0.27)

    insert_record_button = customtkinter.CTkButton(main_screen, text="Add Fitness Record", command=open_insert_record)
    insert_record_button.place(relx=0.27, rely=0.44)

    membership_checker_button = customtkinter.CTkButton(main_screen, text="View Member", command=open_membership_checker)
    membership_checker_button.place(relx=0.27, rely=0.61)

    view_member_data_button = customtkinter.CTkButton(main_screen, text="View Fitness Record", command=open_member_data_viewer)
    view_member_data_button.place(relx=0.27, rely=0.78)

    main_screen.mainloop()

# Call Main GUI Window
open_main_window()
