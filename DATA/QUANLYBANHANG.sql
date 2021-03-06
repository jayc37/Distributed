use QLBANHANG
-- update trạng thái #hd đã thanh toán theo mã hd
go
create procedure sp_updatetrangthai
	(		
			@idhoadon int
	)
	as
	Begin
		update HOADON set	
		Tinhtrang = 1
		where Idhoadon = @idhoadon		
		exec sp_danhsachhoadonchuathanhtoan	 
	End
	exec sp_updatetrangthai 2
go
-- tu dong update tinh trang thanh toan
go
--drop trigger trg_tinhtrangthanhtoan
--alter trigger trg_tinhtrangthanhtoan ON HOADON with encryption
--	after update
--	as
--	begin
--		update HOADON
--		set Tinhtrang = 1
--		where 
--		ngaygiaohang = getdate()
--	end
go

------------------------ doanh thu ngày
GO
	alter proc [dbo].[sp_doanhthungay]
	as
	begin
		select ngaygiaohang , sum(tongtien) as 'Tổng tiền'
		 from HOADON
		where day(ngaygiaohang) = day(getdate())
			and month(ngaygiaohang) = month(getdate())
			and Tinhtrang = 1
		group by ngaygiaohang
	end

GO
	exec sp_doanhthungay
-- doanh thu năm
GO
	CREATE proc [dbo].[sp_doanhthutheonam] with encryption
	as 
	begin
		select year(ngaygiaohang) as 'thoigian', sum(tongtien) as 'Tổng tiền'
		from HOADON
		where year(ngaygiaohang) = year(GETDATE())
			and Tinhtrang = 1
		group by ngaygiaohang
	end
GO
--- doanh thu tháng

GO
	CREATE proc [dbo].[sp_doanhthutheothang] with encryption
	as
	begin
		select ngaygiaohang, sum(tongtien) as 'Tổng tiền'
		from HOADON
		where month(ngaygiaohang) = month(GETDATE())
		group by ngaygiaohang
	end
GO

-- doanh thu tháng chỉ định

GO
	CREATE proc [dbo].[sp_doanhthutheothangchidinh] 
	@thang int
	as
	begin
		select month(ngaygiaohang) as 'Tháng' , sum(tongtien) as 'Tổng tiền'
		from HOADON
		where month(ngaygiaohang) = @thang
		and year(ngaygiaohang) = year(getdate())
		group by ngaygiaohang
	end
GO
-- doanh thu tuần
GO
	create proc [dbo].[sp_doanhthutuan]
	as
	begin
		select ngaygiaohang, sum(tongtien) as 'Tổng tiền'
		from HOADON
		where ngaygiaohang > DATEADD(day,-7,GETDATE())
		group by ngaygiaohang
	end
GO


GO

-- Tính tổng tiền doanh thu
	create FUNCTION f_TongTienDoanhThu
	(
	@NgayStart nvarchar(20),
	@NgayEnd nvarchar(20)
	) 
	RETURNS nvarchar with encryption
	 AS 
	BEGIN 
		 DECLARE @money nvarchar(20); 
		 SELECT @money = Convert(nvarchar(20),sum(ThanhTien))
		 FROM CHITIETHOADON a, HOADON b
		 WHERE
		 a.Idhoadon = b.Idhoadon
		 and b.Tinhtrang = 1 and CONVERT(datetime,b.ngaygiaohang,103) between Convert(datetime,@NgayStart,103) and convert(datetime,@NgayEnd,103);
		 IF (@money = null) 
		   SET @money = 0; 
		 RETURN @money; 
	END
go
-- Liệt kê ds sản phẩm
--
go
	alter proc sp_hienthichitietsanphamnhap
	as
	begin
		select b.Tensanpham, e.Tentheloai, d.Gianhap, b.Giaban, f.Soluongton, b.Trangthai , a.Tenkho into #chitietsanpham
		from KHO a, SANPHAM b, CHITIETHDNHAP d, Theloai e, LUUTRU f
		where b.Idtheloai = e.Idtheloai
		and b.Idsanpham = d.Idsanpham
		and b.Idsanpham = f.Idsanpham
		and f.Idkho = a.Idkho
--	
		select * from #chitietsanpham
	end 
	exec sp_hienthichitietsanphamnhap
go
--
go

alter view dbo.v_hienthichitietsanhphamnhap 
WITH ENCRYPTION
as
		select b.Tensanpham, e.Tentheloai, d.Gianhap, b.Giaban, f.Soluongton, b.Trangthai , a.Tenkho
		from KHO a, SANPHAM b, CHITIETHDNHAP d, Theloai e, LUUTRU f
		where b.Idtheloai = e.Idtheloai
		and b.Idsanpham = d.Idsanpham
		and b.Idsanpham = f.Idsanpham
		and f.Idkho = a.Idkho
go
select * from v_hienthichitietsanhphamnhap
-------------------
-- kiểm tra số lượng tồn trong kho theo từng sản phảm
go
	alter proc sp_kiemtrasoluongton 
	@masp int
	as
		begin
			if exists( select idsanpham from LUUTRU where LUUTRU.Idsanpham = @masp)
			begin
			--kiểm tra có còn hàng hay không
			 if exists(select  trangthai from SANPHAM where SANPHAM.Idsanpham = @masp and sanpham.Trangthai = '1')
				begin
					select a.Tensanpham as 'Tên sản phẩm', d.Tentheloai as 'Tên loại', c.Soluongton as 'Số lượng tồn', b.Tenkho as 'Tên kho'
					from SANPHAM a , KHO b , LUUTRU c, THELOAI d
					where 
					a.Idsanpham = @masp
					and c.Idsanpham = a.Idsanpham
					and a.Idtheloai = d.Idtheloai
						and c.Idkho = b.Idkho
				end
				else
				raiserror ('Sản phẩm đã hết hàng',16,1)
			end
		else
		raiserror('Mã sản phẩm không tồn tại',16,1)
	end

--
	exec sp_kiemtrasoluongton 3
-----
go
----
-- tìm kiếm sản phẩm theo tên sản phẩm
Go
	alter proc sp_timkiemsanpham
		@tensanpham varchar(60)
	as
	begin
		if exists( select Tensanpham from SANPHAM where SANPHAM.Tensanpham like '%'+@tensanpham+'%')
			begin
					select a.Tensanpham as 'Tên sản phẩm', d.Tentheloai as 'Tên loại', c.Soluongton as 'Số lượng tồn', b.Tenkho as 'Tên kho'
					from SANPHAM a , KHO b , LUUTRU c, THELOAI d
					where 
					a.Tensanpham = @tensanpham
					and a.Idsanpham = c.Idsanpham
					and a.Idtheloai = d.Idtheloai
					and c.Idkho = b.Idkho
				end
			else
				raiserror('Sản phẩm không tồn tại',16,1)
	end
	--
	exec sp_timkiemsanpham 'Cocacola'
Go


-- hiển thị danh sách hóa đơn
go
	alter proc sp_hienthichitiethoadon
	as
		begin
			select  b.ngaygiaohang,c.Tenkhachhang , c.Sodienthoai, d.Tensanpham, a.Giahienhanh, a.Soluong, a.Thanhtien
			from CHITIETHOADON a, HOADON b, KHACHHANG c, SANPHAM d
			where a.Idhoadon = b.Idhoadon
			and a.Idsanpham = d.Idsanpham
			and b.Idkhachhang = c.Idkhachhang		
		end
--
	exec sp_hienthichitiethoadon
go
----------------
go
----------------------------
select * from KHACHHANG
-- Removing dynamic data masking on Author column
ALTER TABLE Article   
ALTER COLUMN Author DROP MASKED
ALTER TABLE KHACHHANG 
ALTER COLUMN [Sodienthoai] nvarchar(24) MASKED WITH (FUNCTION = 'default()')
	create view v_hienthichitiethoadon 
		WITH ENCRYPTION
		as
		select  b.ngaygiaohang,c.Tenkhachhang , c.Sodienthoai, d.Tensanpham, a.Giahienhanh, a.Soluong, a.Thanhtien
			from CHITIETHOADON a, HOADON b, KHACHHANG c, SANPHAM d
			where a.Idhoadon = b.Idhoadon
			and a.Idsanpham = d.Idsanpham
			and b.Idkhachhang = c.Idkhachhang
			alter	
-- hien thi chi tiet từng hóa đơn theo mã hóa đơn
select * from v_hienthichitiethoadon
--hien thi chi tiet hoa don trả về bảng có biến
go
	alter function f_hienthichitiethoadon (@id int)
		returns @Chitiethoadonthanhtoan table (
				ngay date,
				tensanpham nvarchar(40),
				giahienhanh money,		
				soluong smallint,
				thanhtien money,
				Tenkhachhang nvarchar(40)
				)
		as
			begin
				insert into @Chitiethoadonthanhtoan
				select b.ngaygiaohang  'Ngày', c.Tensanpham as 'Tên sản phẩm', a.Giahienhanh as 'Giá', a.Soluong as 'Số lượng',  a.Thanhtien 'Tổng tiền', d.Tenkhachhang as 'Tên khách hàng'
				from CHITIETHOADON a, HOADON b, SANPHAM c, KHACHHANG d
				where
					a.Idhoadon = @id 
					and a.Idhoadon = b.Idhoadon
					and a.Idsanpham = c.Idsanpham
					and b.Idkhachhang = d.Idkhachhang
				return
			end	
--
		select * from f_hienthichitiethoadon (1)
go
---
go
-- khi xuất hàng thì số lượng tồn giảm
	alter trigger giamsl ON CHITIETHOADON
	for insert, update 
	AS 
		begin
			SET XACT_ABORT ON
					begin tran
					update LUUTRU
						set soluongton = a.soluongton - b.soluong
						from LUUTRU a, CHITIETHOADON b
						where a.Idsanpham = b.Idsanpham
				commit tran
			SET XACT_ABORT off
		end
go

go
-- kiểm tra số lượng. không được nhập số lượng xuất lớn hơn số lượng tồn
	create trigger trg_kiemtra ON CHITIETHOADON
	for insert
	as
			begin tran
			declare @soluongnhap int, @soluongton int
				select @soluongnhap =  soluong , @soluongton = soluongton 
				from CHITIETHOADON a, LUUTRU b 
				where a.Idsanpham = b.Idsanpham
					if (@soluongnhap > @soluongton) PRINT (N'Không đủ số lượng')
			ROLLBACK TRAN
--- tính tổng trên hóa đơn không được xuất hàng quá số lượng tồn
go
------- trigger tinhtong
go
	alter trigger tinhtong ON CHITIETHOADON
	after insert, update 
	AS 
		begin

			SET XACT_ABORT ON
					begin tran
					update CHITIETHOADON
						set Thanhtien = Soluong * Giahienhanh
					update HOADON
					set tongtien = Thanhtien from HOADON a, CHITIETHOADON b where a.Idhoadon = b.Idhoadon
				commit tran
			SET XACT_ABORT off
		end
go

go

--  Hiển thị danh sách hóa đơn chưa thanh toán
	create procedure sp_danhsachhoadonchuathanhtoan
	as
	begin
		select  distinct *
		from HOADON where Tinhtrang = 0
	end
	exec sp_danhsachhoadonchuathanhtoan
go

-- xóa hóa đơn (chi tiết hóa đơn bị xóa theo)
go
	alter procedure sp_deletehd
	(
		@idhoadon	int
	)
	as
	begin
		delete HOADON where Idhoadon = @idhoadon
		delete CHITIETHOADON where Idhoadon = @idhoadon
	end
exec sp_deletehd 1
go

---
GO
-- Không được phép xóa hóa đơn đã thanh toán
	Create Trigger Trigger_Xoahoadon
	ON Hoadon  with encryption
	FOR DELETE
		AS
		BEGIN
			DECLARE @trangthai bit
			SELECT @trangthai = Tinhtrang FROM deleted
			IF (@trangthai = 1)
			BEGIN
			PRINT N'Không được phép xóa hóa đơn đã thanh toán !!!'
				ROLLBACK TRAN
			END
		END
GO

go
---------------------------------------------- PHÂN QUYỀN NGƯỜI DÙNG---------------------------------------------------------------

go
use QLBANHANG
create role QLBANHANG_quanly
grant select, references on  [dbo].[SANPHAM] to QLBANHANG_quanly
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[CHITIETHOADON] to QLBANHANG_quanly
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[HOADON] to QLBANHANG_quanly
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[KHACHHANG] to QLBANHANG_quanly
grant select, insert, references on [dbo].[NHANVIEN] to QLBANHANG_quanly
grant select  on [dbo].[THELOAI] to QLBANHANG_quanly
grant select on [dbo].[KHO] to QLBANHANG_quanly
grant select on [dbo].[SHIPPER] to QLBANHANG_quanly
grant select on [dbo].[LUUTRU] to QLBANHANG_quanly
grant select on [dbo].[NHACUNGCAP] to QLBANHANG_quanly
grant select on [dbo].[CHITIETHDNHAP] to QLBANHANG_quanly
grant select on [dbo].[HOADONNHAP] to QLBANHANG_quanly
go
--
go
use QLBANHANG
create role QLBANHANG_nhanvien
grant select on  [dbo].[SANPHAM] to QLBANHANG_nhanvien
grant SELECT, INSERT on [dbo].[CHITIETHOADON] to QLBANHANG_nhanvien
grant SELECT, INSERT on [dbo].[HOADON] to QLBANHANG_nhanvien
grant SELECT, INSERT on [dbo].[KHACHHANG] to QLBANHANG_nhanvien
grant select, insert, references on [dbo].[NHANVIEN] to QLBANHANG_nhanvien
grant select on [dbo].[THELOAI] to QLBANHANG_nhanvien
grant select on [dbo].[KHO] to QLBANHANG_nhanvien
grant select on [dbo].[SHIPPER] to QLBANHANG_nhanvien
grant select on [dbo].[LUUTRU] to QLBANHANG_nhanvien
go
--
go
use QLBANHANG
create role QLKHO
grant SELECT, INSERT, UPDATE, DELETE on  [dbo].[SANPHAM] to QLKHO
grant SELECT, INSERT, UPDATE, DELETE  on [dbo].[THELOAI] to QLKHO
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[KHO] to QLKHO
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[LUUTRU] to QLKHO
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[NHACUNGCAP] to QLKHO
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[CHITIETHDNHAP] to QLKHO
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[HOADONNHAP] to QLKHO
go
--
go
use QLBANHANG
create role QLNHANSU

grant SELECT, INSERT, UPDATE, DELETE on [dbo].[NHANVIEN] to QLNHANSU
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[SHIPPER] to QLNHANSU
go

go
--
use QLBANHANG
create role QLCHUNGTU
grant select on  [dbo].[SANPHAM] to QLCHUNGTU
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[CHITIETHOADON] to QLCHUNGTU
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[HOADON] to QLCHUNGTU
grant SELECT on [dbo].[KHACHHANG] to QLCHUNGTU
grant select  on [dbo].[THELOAI] to QLCHUNGTU
grant select on [dbo].[KHO] to QLCHUNGTU
grant select on [dbo].[SHIPPER] to QLCHUNGTU
grant select, references on [dbo].[LUUTRU] to QLCHUNGTU
grant select, references on [dbo].[NHACUNGCAP] to QLCHUNGTU
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[CHITIETHDNHAP] to QLCHUNGTU
grant SELECT, INSERT, UPDATE, DELETE on [dbo].[HOADONNHAP] to QLCHUNGTU

go


use QLBANHANG
----- thêm hóa đơn exec sp_Themhoadon_tran 6,'KH1',3,'2019/12/15','day ne',1,6,'120000',10,'0',null
go
-- thêm hóa đơn
	alter proc sp_Themhoadon_tran				
				@idhd int,
				@idkhachhang nchar(5),
				@idnhanvien int,
				@NgayOrder date,
				@diachiship nvarchar(60),
				@magiaohang int,
				@idsanpham int,
				@giahienhanh money,
				@soluong smallint,
				@giamgia real,
				@VAT nvarchar(10)
			as
			begin
					---- find ma hoa don
					select @idhd = 1
					while (exists (select * from HOADON where Idhoadon = @idhd))
						select @idhd = @idhd + 1
					--error auto rollback
					SET XACT_ABORT ON
					-- tran
					begin tran
						insert into HOADON
							values (@idhd,@idkhachhang,@idnhanvien,@NgayOrder,@diachiship,'false',@magiaohang,null)	
						insert into CHITIETHOADON
							values (@idhd,@idsanpham,@giahienhanh,@soluong,@giamgia,null,@VAT)
					commit tran
				SET XACT_ABORT off
			end
go
--
----------------------------------------------------------
select * from CHINHANH
select * from CHINHANHpk

use QuanLyQuanAn_DoAnCuoiKi 
select * from NHANVien
